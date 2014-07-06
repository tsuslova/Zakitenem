from google.appengine.ext import ndb

import logging
import datetime
import time
import json
from hashlib import sha256
from random import random
from math import trunc
from constants import constants
 
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

# Helper class to load/dump login information for requests.
# TODO: Looks like it shouldn't be an ndb.Model as it is not used to store data in DB  
class LoginInfo(ndb.Model):
    # required:
    login = ndb.StringProperty()
    device_id = ndb.StringProperty()
    #optional
    password = ndb.StringProperty()
    device_token = ndb.StringProperty()
    
    def data(self):
        login_info = {constants.login_key:self.login,
                      constants.password_key:self.password,
                      constants.device_id_key:self.device_id,
                      constants.device_token_key:self.device_token}
        return json.dumps(login_info)
        
    
def login_info_from_data(data):
    login_info = LoginInfo()
    login_info_json = json.loads(data)
    login_info.login = login_info_json.get(constants.login_key)
    login_info.password = login_info_json.get(constants.password_key)
    login_info.device_id = login_info_json.get(constants.device_id_key)
    login_info.device_token = login_info_json.get(constants.device_token_key)
    return login_info

def login_info(login, device_id, device_token="", password=""):
    if len(login) == 0 or len(device_id) == 0:
        logger.warning("Required params not filled: %s(login) %s(device_id)"%(login, device_id))
    login_info = LoginInfo()
    login_info.login = login
    login_info.password = password
    login_info.device_id = device_id
    login_info.device_token = device_token
    return login_info 

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
    
    def resp(self):
        user_data = dict()
        user_data[constants.login_key] = self.login
        user_data[constants.email_key] = self.email
        user_data[constants.phone_key] = self.phone
        user_data[constants.gender_key] = self.gender
        user_data[constants.userpic_key] = self.userpic
        user_data[constants.region_key] = self.region
        return json.dump(user_data)
        
    
def ssshh(p, param):
    test = "DFSzF3q3Q34OIq7QRGWNERLWIU4aIQ3"
    result = sha256('%s%s%s'%(test, p, param))
    return result

def user_by_login(login):
    query = UserItem.query(UserItem.login == login)
    user = query.fetch(1)
    logger.warning("user %s for login %s"%(user,login))
    return user

def validate_password(password):
    #TODO check the password
    return True

def create_installation(device_id, device_token, cookie):
    #TODO add (or update?) installation for the existing user
    pass

def create_user_from_login_info(login_info, cookie):
    pass_not_empty = login_info.password and len(login_info.password) > 0
    password_hash = ssshh(login_info.password, login_info.device_id) if pass_not_empty else ""
    logger.warning("password %s (%@)"%(login_info.password, password_hash))
    user = UserItem(login=login_info.login, password=password_hash)
    app_install = AppInstallation(device_id=login_info.device_id, 
                                  device_token=login_info.device_token, cookie=cookie)
    user.app_installations = [app_install]
    user.put()
    logger.warning("user %s created"%(user))
    return user
