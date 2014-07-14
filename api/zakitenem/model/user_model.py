from google.appengine.ext import ndb

import logging
import datetime
import time
import json
import hashlib, binascii

from math import trunc
from constants import constants
from constants import error_definitions
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
    # optional
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

def create_login_info(login, device_id, device_token="", password=""):
    if len(login) == 0 or len(device_id) == 0:
        logger.warning("Required params not filled: %s(login) %s(device_id)" % (login, device_id))
    login_info = LoginInfo()
    login_info.login = login
    login_info.password = password
    login_info.device_id = device_id
    login_info.device_token = device_token
    return login_info 

class AppInstallation(ndb.Model):
    device_id = ndb.StringProperty()
    device_token = ndb.StringProperty(indexed=False)
    cookie = ndb.StringProperty()
    date = ndb.DateTimeProperty(auto_now_add=True)     
    
class UserItem(ndb.Model):
    login = ndb.StringProperty()
    
    email = ndb.StringProperty(indexed=False)
    phone = ndb.StringProperty()
    
    gender = ndb.BooleanProperty()
    password = ndb.StringProperty(indexed=False)
    some_data = ndb.StringProperty(indexed=False)
    
    # TODO need store userpic as a link 
    userpic = ndb.StringProperty(indexed=False)
    # TODO: how to store user region?
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
        resp = {constants.user_key:user_data}
        logger.info("Resp %s" % resp)
        return json.dumps(resp)
    
    def validate_password(self, password):
        pass_empty = self.password == None or len(self.password) == 0
        if pass_empty:
            logger.info("User has empty password - no way to login with password")
            return error_definitions.msg_account_used, error_definitions.code_account_used
        if password == None or len(password) == 0:
            logger.info("Password is empty")
            return error_definitions.msg_wrong_password, error_definitions.code_wrong_password
        
        password_hash = ssshh(password, self.some_data)
        if password_hash == self.password: 
            return None, 0
        return error_definitions.msg_wrong_password, error_definitions.code_wrong_password
    
    def create_installation(self, device_id, device_token, cookie):
        app_install = None
        for each in self.app_installations:
            if each.device_id == device_id:
                app_install = each
                break
        if app_install == None:
            logger.info("Create a new AppInstallation (parent %s)"%self.key)
            app_install = AppInstallation(device_id=device_id, device_token=device_token,
                                              cookie=cookie, parent=self.key)
            self.app_installations.append(app_install)
        else:
            logger.info("app_install would be updated  (%s)" % (app_install))
            app_install.populate(device_token=device_token, cookie=cookie)
        
        self.put()

class UserByCookieItem(ndb.Model):
    cookie = ndb.StringProperty()
    user = ndb.KeyProperty(UserItem)
    
def ssshh(p, param):
    test = "DFSzF3q3Q34OIq7QRGWNERLWIU4aIQ3"
    result = hashlib.sha256('%s%s%s' % (test, p, param)).hexdigest()
    return result

def debug_print_users():
    query = UserItem.query()
    print query.fetch(10)
    
def user_by_login(login):
    user = UserItem.get_by_id(id=login)
    logger.info("user %s for login %s" % (user, login))
    return user 

def user_by_cookie(cookie):
    user_by_cookie = UserByCookieItem.get_by_id(id=cookie)
    user = user_by_cookie.user.get()
    logger.info("user %s for cookie %s" % (user, cookie))
    return user

@ndb.transactional(xg=True)
def create_user_from_login_info(login_info, cookie):
    pass_not_empty = login_info.password != None and len(login_info.password) > 0
    password_hash = ssshh(login_info.password, login_info.device_id) if pass_not_empty else ""
    logger.info("password  (%s)" % (password_hash))
    user = UserItem.get_by_id(id=login_info.login)
    if user:
        logger.critical("user %s is already created" % (user))
        return None
    user = UserItem(id=login_info.login)
    user.login = login_info.login
    user.password = password_hash
    user.some_data = login_info.device_id
    user.create_installation(login_info.device_id, login_info.device_token, cookie)
    user_by_cookie = UserByCookieItem(id=cookie, cookie=cookie, user=user.key)  
    ndb.put_multi([user_by_cookie, user])
    logger.info("user %s created" % (user))
    return user
    
        
        
        
        
        
