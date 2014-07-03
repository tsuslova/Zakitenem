from google.appengine.ext import ndb

import logging
import datetime
import time
from hashlib import sha256
from random import random
from math import trunc
        
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

SIMPLE_TYPES = (int, long, float, bool, dict, basestring, list)
NON_SERIALIZABLE_PROPERTIES = ("password", "cookie", "app_installations")

def to_dict(model):
    output = {}

    for key, prop in model.properties().iteritems():
        if (prop in NON_SERIALIZABLE_PROPERTIES):
            continue
        value = getattr(model, key)

        if value is None or isinstance(value, SIMPLE_TYPES):
            output[key] = value
        elif isinstance(value, datetime.date):
            # Convert date/datetime to MILLISECONDS-since-epoch (JS "new Date()").
            ms = time.mktime(value.utctimetuple()) * 1000
            ms += getattr(value, 'microseconds', 0) / 1000
            output[key] = int(ms)
        elif isinstance(value, ndb.GeoPt):
            output[key] = {'lat': value.lat, 'lon': value.lon}
        elif isinstance(value, ndb.Model):
            output[key] = to_dict(value)
        else:
            raise ValueError('cannot encode ' + repr(prop))
    return output



class AppInstallation(ndb.Model):
    device_id = ndb.StringProperty(indexed=False)
    device_token = ndb.StringProperty(indexed=False)
    cookie = ndb.StringProperty()
    timestamp = ndb.IntegerProperty() 

    def __init__(self, *args, **kwargs):
        super(ndb.Model, self).__init__(*args, **kwargs)
        self.timestamp = trunc(time.time())
    
class UserItem(ndb.Model):
    login = ndb.StringProperty()
    
    email = ndb.StringProperty(indexed=False)
    phone = ndb.StringProperty(indexed=False)
    
    gender = ndb.BooleanProperty()
    #TODO! store password hash - not a password
    password = ndb.StringProperty(indexed=False)
    
    #TODO need store userpic as a link 
    userpic = ndb.StringProperty(indexed=False)
    #TODO: how to store user region?
    region = ndb.StringProperty()
    
    app_installations = ndb.StructuredProperty(AppInstallation, repeated=True)
    
def ssshh(p, param):
    test = "DFSzF3q3Q34OIq7QRGWNERLWIU4aIQ3"
    result = sha256('%s%s%s'%(test, p, param))
    return result

def user_by_login(login):
    query = UserItem.query(UserItem.login == login)
    user = query.fetch(1)
    logger.warning("user %s for cookie %s"%(user,login))
    return user

def validate_password(password):
    #TODO check the password
    return True

def create_installation(device_id, device_token, cookie):
    #TODO add (or update?) installation for the existing user
    pass

def create_user(login, password, device_id, device_token, cookie):
    password_hash = password and len(password)>0 if ssshh(password, device_id) else ""
    logger.warning("password %s (%@)"%(password, password_hash))
    user = UserItem(login=login, password=password_hash)
    app_install = AppInstallation(device_id=device_id, device_token=device_token, cookie=cookie)
    user.app_installations = [app_install]
    user.put()
    logger.warning("user %s created"%(user))
    return user

