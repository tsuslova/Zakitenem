from google.appengine.ext import db

import logging
import datetime
import time

logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

SIMPLE_TYPES = (int, long, float, bool, dict, basestring, list)
PROHIBITED_PROPERTIES = ("password", "cookie",)

def to_dict(model):
    output = {}

    for key, prop in model.properties().iteritems():
        if (prop in PROHIBITED_PROPERTIES):
            continue
        value = getattr(model, key)

        if value is None or isinstance(value, SIMPLE_TYPES):
            output[key] = value
        elif isinstance(value, datetime.date):
            # Convert date/datetime to MILLISECONDS-since-epoch (JS "new Date()").
            ms = time.mktime(value.utctimetuple()) * 1000
            ms += getattr(value, 'microseconds', 0) / 1000
            output[key] = int(ms)
        elif isinstance(value, db.GeoPt):
            output[key] = {'lat': value.lat, 'lon': value.lon}
        elif isinstance(value, db.Model):
            output[key] = to_dict(value)
        else:
            raise ValueError('cannot encode ' + repr(prop))
    return output

class UserItem(db.Model):
    login = db.StringProperty()
    
    email = db.StringProperty()
    phone = db.StringProperty()
    
    gender = db.Property(bool)
    #TODO! store password hash - not a password
    password = db.StringProperty()
    
    userpic = db.BlobProperty()
    #TODO: how to stroe user region?
    region = db.StringProperty()
    
# def user_by_login():
    

class AppInstallation(db.Model):
    udid = db.StringProperty()
    device_token = db.StringProperty()
    cookie = db.StringProperty()
    
    user = db.ReferenceProperty(UserItem)
