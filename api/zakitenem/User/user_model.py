from google.appengine.ext import ndb
from google.appengine.api import mail

import logging
import datetime
from lib.dateutil import tz
import json
import hashlib

import message 
from Forecast import message as ForecastMessage
from constants import constants, error_definitions, ru_locale

logger = logging.getLogger()
logger.setLevel(logging.DEBUG)


# TODO : change before release: 
use_sandbox = True

# Helper class to load/dump login information for requests.
# TODO: Looks like it shouldn't be an ndb.Model as it is not used to store data in DB  
class LoginInfoItem(ndb.Model):
    # required:
    login = ndb.StringProperty()
    device_id = ndb.StringProperty()
    # optional
    password = ndb.StringProperty()
    device_token = ndb.StringProperty()
    
    def login_json(self):
        login_info = {constants.login_key:self.login,
                      constants.password_key:self.password,
                      constants.device_id_key:self.device_id,
                      constants.device_token_key:self.device_token}
        return login_info 
        
    @classmethod
    def from_message(cls, message):
        login_info = LoginInfoItem(login=message.login, device_id=message.device_id,
                               password=message.password, device_token=message.device_token)
        return login_info
    
def login_info_from_data(data):
    login_info = LoginInfoItem()
    login_info_json = json.loads(data)
    login_info.login = login_info_json.get(constants.login_key)
    login_info.password = login_info_json.get(constants.password_key)
    login_info.device_id = login_info_json.get(constants.device_id_key)
    login_info.device_token = login_info_json.get(constants.device_token_key)
    return login_info

def create_login_info(login, device_id, device_token="", password=""):
    if len(login) == 0 or len(device_id) == 0:
        logger.warning("Required params not filled: %s(login) %s(device_id)" % (login, device_id))
    login_info = LoginInfoItem()
    login_info.login = login
    login_info.password = password
    login_info.device_id = device_id
    login_info.device_token = device_token
    return login_info 

  

class RegionItem(ndb.Model):
    id = ndb.StringProperty()
    name = ndb.StringProperty()
    
    latitude = ndb.FloatProperty()
    longitude = ndb.FloatProperty()
    
    def to_message(self):
        return message.Region(id=self.id,
                              name=self.name,
                              latitude=self.latitude,
                              longitude=self.longitude
                              )
    @classmethod
    def from_message(cls, message):
        region = cls.get_or_insert(message.id, id=message.id, name=message.name,
                                    latitude=message.latitude, longitude=message.longitude)
        return region
    
class UserStatusItem(ndb.Model):
    spot_id = ndb.StringProperty()
    user_region_id = ndb.StringProperty()

    status = ndb.IntegerProperty()  # kStatus...
    post_date = ndb.DateTimeProperty()
    status_date = ndb.DateProperty()
    comment = ndb.StringProperty()
    wind_from = ndb.IntegerProperty()
    wind_to = ndb.IntegerProperty()
    gps_on = ndb.BooleanProperty()  # ??? TODO
    # TODO user key?? or add a status to user.statuses??
    
    def status_date_string(self):
        dt = datetime.datetime(self.status_date.year, self.status_date.month, self.status_date.day)
        
        dt.strftime(constants.common_date_format)
        
    @classmethod
    def get_user_status_list(cls, user):
        actual_statuses = cls.query(ancestor = user.key, filters=ndb.AND(
                                       cls.status_date >= datetime.date.today())
                                   ).fetch()
        statuses_message = [status_item.to_message() for status_item in actual_statuses]
        return message.UserStatusList(statuses = statuses_message)
    
    @classmethod
    def status_date_from_string(self, date_string):
        return datetime.datetime.strptime(date_string, constants.common_date_format).date()
    
    @classmethod
    def get_last_user_spot_status(cls, message, user):
        status_date_final = cls.status_date_from_string(message.status_date)
        previous_statuses = cls.query(ancestor = user.key, filters=ndb.AND(
                                       cls.spot_id == message.spot.id, 
                                       cls.status_date == status_date_final
                                       )).order(-cls.post_date).fetch(1)
        if previous_statuses and len (previous_statuses) > 0:
            #Return the last status user set for the spot 
            return previous_statuses[0] 
        return None
        
    @classmethod
    def from_message(cls, message, user):
        status_date_final = cls.status_date_from_string(message.status_date)
        message_post_date = message.post_date
        if not message.post_date:
            message_post_date = datetime.datetime.now()
        status = UserStatusItem(spot_id=message.spot.id,
                                user_region_id = message.user_region_id, 
                                status=message.status,
                                post_date=message_post_date,
                                status_date = status_date_final,
                                comment = message.comment,
                                wind_from = message.wind_from,
                                wind_to = message.wind_to,
                                gps_on = message.gps_on,
                                parent = user.key)
        logger.info(" new user status added %d", status.status)
        return status
    
    def to_message(self):
        spot = ForecastMessage.spot_by_id(self.spot_id) 
        
        return message.UserStatus(spot = spot,
                              status = self.status,
                              post_date  = self.post_date,
                              status_date = self.status_date_string(),
                              comment = self.comment,
                              wind_from = self.wind_from,
                              wind_to = self.wind_to,
                              gps_on = self.gps_on
                              )
                          
    @classmethod
    def get_actual_spot_statuses(cls, spot_id, region_id):
        logger.info("get_actual_spot_statuses %s (%s)"%(spot_id, region_id))
        actual_statuses = cls.query(filters=ndb.AND(
                                       cls.user_region_id == region_id,
                                       cls.spot_id == spot_id, 
                                       cls.status_date >= datetime.date.today())
                                   ).fetch()
        statuses_message = []
        for status_item in actual_statuses:
            if status_item.status != constants.kStatusNone:
                statuses_message.append(status_item.to_message())
        return message.UserStatusList(statuses = statuses_message)
             
    @classmethod
    def get_spot_status_list(cls, spot):
        return cls.get_actual_spot_statuses(spot.id, None)
    
    @classmethod
    def get_actual_status_list(cls):
        actual_statuses = cls.query(filters=ndb.AND( 
                                       cls.status_date >= datetime.date.today())
                                   )
        return actual_statuses
        
        
    
class UserItem(ndb.Model):
    login = ndb.StringProperty()
    
    email = ndb.StringProperty(indexed=False)
    phone = ndb.StringProperty()
    
    gender = ndb.BooleanProperty()
    password = ndb.StringProperty(indexed=False)
    password_set = ndb.BooleanProperty()
    
    some_data = ndb.StringProperty(indexed=False)
    
    userpic = ndb.BlobProperty(indexed=False)
    birthday = ndb.DateTimeProperty()
    
    region = ndb.StructuredProperty(RegionItem, indexed=False)
    subscription_end_date = ndb.DateTimeProperty()
    
    friend_list_ids = ndb.StringProperty(repeated=True)

    forecast_get_time = ndb.DateTimeProperty()
    
    # app_installations = ndb.StructuredProperty(AppInstallationItem, repeated=True)
    
    updatable_properties = ["email", "phone", "gender", "password", "password_set", "userpic",
                            "region", "birthday", "friend_list_ids"]
    
    def get_region_id(self):
        region = self.region.id if self.region else constants.default_region
        return region
        
    def to_message(self, app_installation):
        session = message.Session(cookie=app_installation.cookie,
                  expires=str(app_installation.expires)) if app_installation else None
        region_message = self.region.to_message() if self.region else None
        
        return message.User(login=self.login,
                           email=self.email,
                           phone=self.phone,
                           gender=self.gender,
                           password_set=self.password_set,
                           userpic=self.userpic,
                           birthday=self.birthday,
                           region = region_message,
                           session=session,
                           friend_list_ids=self.friend_list_ids 
                           )
    
    def validate_password(self, password):
        pass_empty = self.password == None or len(self.password) == 0
        if pass_empty:
            logger.info("User has empty password - no way to login with password")
            return error_definitions.msg_account_used
        if password == None or len(password) == 0:
            logger.info("Password is empty")
            return error_definitions.msg_wrong_password
        password_hash = ssshh(password, self.some_data)
        if password_hash == self.password: 
            return None
        return error_definitions.msg_wrong_password
        
    def send_password(self, request):
        import os
        tool = request.tool
        password = os.urandom(8).encode("base-64")
        logger.info("generate password: %s" % password)
        if constants.option_email == tool:
            sender = "Support <%s>" % constants.zakitenem_email
            to = "%s <%s>" % (self.login, self.email)
            body = ru_locale.resstore_pass_body % password
            logger.info("send email from: %s to : %s" % (sender, to))
            mail.send_mail(sender=sender, to=to,
              subject = ru_locale.resstore_pass_subject,
              body=body)
            
            logger.info("save its hash to db %s %s" % (password, self.some_data))
            self.password = ssshh(password, self.some_data)
            self.password_set = True
            self.put()
            return self.email
        if constants.option_push == tool:
            pushed_to = []
            for inst in user_app_installations(self):
                if inst.device_token and len (inst.device_token) > 0:
                    pushed_to.append(inst.device_token)
                    self.push_password(password, self, inst.device_token)
            self.password = ssshh(password, self.some_data)
            self.password_set = True
            self.put()
            return pushed_to

    def push_password(self, password, token):
        from PyAPNs.apns import APNs, Payload
        apns = APNs(use_sandbox=use_sandbox, cert_file='./resources/dev_push.pem')
        payload = Payload(alert=password, sound="default", badge=1, custom={})
        apns.gateway_server.send_notification(token, payload)
        for (token, fail_time) in apns.feedback_server.items():
            logging.info(token)
            logging.info(fail_time)
    
    def set_properties(self, user_message):
        logger.info(user_message)
        for key in self.updatable_properties:
            val = getattr(user_message, key)
            if val:
                # TODO check that val is Message field and iterate through fields instead?
                if key == "region":
                    self.region = RegionItem.from_message(val)
                elif key == "gender":
                    self.gender = True if val > 0 else False
                elif key == "password":
                    pass_not_empty = val != None and len(val) > 0
                    self.password = ssshh(val, self.some_data) if pass_not_empty else ""
                    self.password_set = pass_not_empty
                elif isinstance(val, datetime.date):
                    logging.info("val %s" % str(val))
                    if val.tzinfo is not None:
                        val = val.astimezone(tz.tzutc()).replace(tzinfo=None)
                    logging.info("val %s" % str(val))
                    setattr(self, key, val)
                else: 
                    setattr(self, key, val)
                    
        self.put() 
        
class AppInstallationItem(ndb.Model):
    device_id = ndb.StringProperty()
    device_token = ndb.StringProperty(indexed=False)
    
    cookie = ndb.StringProperty()
    expires = ndb.DateProperty()
    # installation date
    date = ndb.DateTimeProperty(auto_now_add=True)     
    
    user = ndb.KeyProperty(UserItem)
    
def user_app_installations(user):
    return AppInstallationItem.query(ndb.GenericProperty("user") == user.key).fetch()

def user_installation(user, device_id):
    user_app_installs = user_app_installations(user)
    logger.info("TODO: is it possible not to fetch all the installations?")
    if len(user_app_installs) > 0:
        for each in user_app_installs:
            logger.info("%s" % each.device_id)
            if each.device_id == device_id:
                app_install = each
                return app_install
    return None

def create_installation(user, device_id, device_token, app_install=None):
    logger.info("AppInstallationItem.query") 
    
    cookie, expires = new_cookie()
    if app_install:
        logger.info("app_install would be removed  (%s)" % (app_install))
        app_install.key.delete()
    
    logger.info("Create a new AppInstallation")
    app_install = AppInstallationItem(id=cookie, device_id=device_id, device_token=device_token,
                          cookie=cookie, expires=expires, user=user.key)
    app_install.put()
    return app_install
        
def ssshh(p, param):
    test = "DFSzF3q3Q34OIq7QRGWNERLWIU4aIQ3"
    result = hashlib.sha256('%s%s%s' % (test, p, param)).hexdigest()
    return result

def debug_print_users():
    query = UserItem.query()
    print query.fetch(10)
    
def user_by_login(login):
    user = UserItem.get_by_id(id=login.lower())
    logger.info("user %s for login %s" % (user, login))
    return user 

def installation_by_cookie(cookie):
    installation_by_cookie = AppInstallationItem.get_by_id(id=cookie)
    if not installation_by_cookie:
        logger.error("User not found")
        return None
    return installation_by_cookie

def user_by_installation(installation):
    if installation.expires < datetime.date.today():
        logger.error("Cookie expired %s %s" % (str(installation.expires),
                                             str(datetime.date.today())))
        return None
    user = installation.user.get()
    logger.info("user %s for installation %s" % (user, installation))
    return user
    
def user_by_cookie(cookie):
    logger.info("user_by_cookie = %s"%cookie)
    installation = installation_by_cookie(cookie)
    return user_by_installation(installation)

def create_user_from_login_info(login_info):
    pass_not_empty = login_info.password != None and len(login_info.password) > 0
    password_hash = ssshh(login_info.password, login_info.device_id) if pass_not_empty else ""
    logger.info("password  (%s)" % (password_hash))
    user = UserItem.get_by_id(id=login_info.login.lower())
    if user:
        logger.critical("user %s is already created" % (user))
        return None
    user = UserItem(id=login_info.login.lower())
    logger.info("Create user")
    user.login = login_info.login
    user.password = password_hash
    user.password_set = pass_not_empty
    user.some_data = login_info.device_id
    logger.info("create_installation")
    app_install = create_installation(user, login_info.device_id, login_info.device_token)
    user.put()
    logger.info("user %s created (app_install=%s)" % (user, app_install))
    return user, app_install

def new_cookie():
    import os
    logger.info("Generate cookie") 
    cookie = os.urandom(64).encode("base-64")
    cookie = cookie.replace("\n", "")
    logger.info("%s" % cookie) 
    expires = datetime.datetime.utcnow() + datetime.timedelta(days=6 * 30)  # expires in 6 months
    return cookie, expires
        
# Spot Ratings:  

# Each spotStatus rating should be multiplied by the status coefficients
def get_status_coefficient(status):
    coefficients = {constants.kStatusInterest : 1, 
     constants.kStatusWant : 1.5,
     constants.kStatusGo : 2,
     constants.kStatusOnSpot : 2.5,
     constants.kStatusFail : 0.5,
     constants.kStatusNone : 0}
    return coefficients[status]
    
def get_day_status_coefficient(status_date):
    delta = status_date - datetime.date.today()
    diff_from_today = delta.days + 1.1
    return 1 + 1/diff_from_today 
    
class SpotRatingItem(ndb.Model):
    region_id = ndb.StringProperty()
    spot_id = ndb.StringProperty()
    rating = ndb.FloatProperty()
    valid_date = ndb.DateProperty()
    
    go_count = ndb.IntegerProperty(default=0)
    on_spot_count = ndb.IntegerProperty(default=0)
    others_count = ndb.IntegerProperty(default=0)
    #Here it is float as it might be mean from several values
    #TODO fill them:
    wind_from = ndb.FloatProperty()
    wind_to = ndb.FloatProperty()
    
    
    def summary(self):
        def append_str(base_string, suffix_string):
            if not suffix_string or len(suffix_string) == 0:
                return base_string
            if len(base_string) > 0:
                base_string = base_string + ", "
            return base_string + suffix_string
            
        summary_string = ""
        if self.go_count > 0:
            summary_string = append_str(summary_string, ru_locale.go_format%self.go_count)
        if self.on_spot_count > 0:
            summary_string = append_str(summary_string, ru_locale.onspot_format%self.on_spot_count)
        if self.others_count > 0:
            summary_string = append_str(summary_string, ru_locale.interest_format%self.others_count)
#         print "summary_string",summary_string
        return summary_string
    
    def to_message(self):
        return ForecastMessage.SpotRating(region_id = self.region_id,
                                          spot_id = self.spot_id,
                                          summary = self.summary().decode('utf-8'))
        
    #If status is new (shoul be added to counters) step should be = 1.
    #If it's old - pass -1 to decrement counters 
    def adjust_rating_for_status(self, status, step):
        if status:
            if status.status == constants.kStatusGo:
                self.go_count += step
            if status.status == constants.kStatusOnSpot:
                self.on_spot_count += step
            if (status.status == constants.kStatusInterest or 
                status.status == constants.kStatusWant or
                status.status == constants.kStatusFail):
                self.others_count += step
                
    @classmethod
    def calculate_rating_for_status(cls, rating, status, spot, last_status_item = None):
        valid_date = datetime.datetime.today()
        if not rating:
            rating = SpotRatingItem(spot_id = status.spot_id,
                                    region_id = status.user_region_id,
                                    rating = spot.default_rating,
                                    valid_date = valid_date)
            logger.info ("add rating (with default value) for spot %s"%status.spot_id)
        else:
            logger.info ("update spot rating %s"%status.spot_id)
        status_coef = get_status_coefficient(status.status)
        logger.info ("status_coef %f"%status_coef)
        day_coef = get_day_status_coefficient(status.status_date)
        logger.info ("day_coef %f"%day_coef)
        # if last_status_item - minus it
        previous_coef = get_status_coefficient(last_status_item.status) if last_status_item else 0
        logger.info ("previous_coef %f"%previous_coef)
        status_rating_add = day_coef*(status_coef-previous_coef)
        
        rating.rating = rating.rating + status_rating_add
        logger.info ("new rating %f"%rating.rating)
        
        rating.adjust_rating_for_status(last_status_item, -1)
        rating.adjust_rating_for_status(status, 1)
        
        return rating
    
    #TODO may be it's better to make this call async:
    #when actual rating is not found - old rating is returned and new calculations are started?
    
    #requested_spot - optional parameter for case when rating calculation is started while status 
    #is added, it is more comfortable not to select requested rating for status twice  
    @classmethod
    def calculate_ratings(cls, requested_spot=None):
        rating_dict = dict()
        
        all_spots = ForecastMessage.get_all_spots_dict()

        for status in UserStatusItem.get_actual_status_list():
            if status.status != constants.kStatusNone:
                spot = all_spots.get(status.spot_id)
                logger.info("status %d found for spot %s"%(status.status, status.spot_id))
                rating_key = "%s_%s"%(status.spot_id, status.user_region_id)
                rating = rating_dict.get(rating_key)
                rating = cls.calculate_rating_for_status(rating, status, spot)
                
                rating_dict[status.spot_id] = rating
        ndb.put_multi(rating_dict.itervalues())
        if requested_spot:
            return rating_dict[requested_spot.id]
        return []
        
    @classmethod  
    def update_rating_with_status(cls, status, last_status_item):
        spot_ratings = SpotRatingItem.query(filters=ndb.AND(cls.region_id == status.user_region_id,
                                  cls.spot_id == status.spot_id,
                                  cls.valid_date == datetime.date.today()
                                  )).fetch(1)
                                          
        #if actual rating for spot not found it might be because 
        # 1. No statuses for the spot yet
        # 2. Ratings were not calculated today yet
        # If there are statuses, but no ratings are calculated - need have calculate 
        statuses = UserStatusItem.get_actual_spot_statuses(status.spot_id, status.user_region_id)
        spot_rating = None
        if len(statuses.statuses) > 0 and len(spot_ratings) == 0:
            spot_rating = cls.calculate_ratings()
        else:
            if len(spot_ratings) > 0:
                spot_rating = spot_ratings[0]
        all_spots = ForecastMessage.get_all_spots_dict()
        spot = all_spots.get(status.spot_id)
        rating = cls.calculate_rating_for_status(spot_rating, status, spot, last_status_item)
        rating.put()
        #TODO: add rating for different region too?
    
    @classmethod  
    def get_user_top_ratings(cls, user):
        logger.info("get_user_top_ratings")
        user_statuses = UserStatusItem.query(ancestor = user.key, filters=ndb.AND(
                                       UserStatusItem.status_date >= datetime.date.today())
                                   ).fetch()
        all_spots = ForecastMessage.get_all_spots_dict()
        rating_dict = {}
        user_ratings = []
        user_statuses.sort(key = lambda x : x.post_date)
        for status in user_statuses:
            if status.status != constants.kStatusNone:
                rating_key = "%s"%(status.spot_id)
                rating = rating_dict.get(rating_key)
                if not rating:
                    spot = all_spots.get(status.spot_id)
                    rating = cls.calculate_rating_for_status(rating, status, spot)
                    rating_dict[status.spot_id] = rating
                    new_rating_index = 0
                    for user_rating in user_ratings:
                        if rating.rating < user_rating.rating:
                            new_rating_index +=1
                    user_ratings.insert(new_rating_index, rating)
        return user_ratings   
        
    @classmethod  
    def get_top_ratings(cls, user, count):
        region_id = constants.default_region 
        if user and user.region:
            region_id = user.region.id 
        else:
            logger.info("No user region found - use default one")
        
        ratings = cls.query(filters=ndb.AND(cls.region_id == region_id, 
                                  cls.valid_date == datetime.date.today()
                                  )).order(-cls.rating).fetch(count)
        #TODO: save ratings to memcache?
        if len(ratings) == 0:
            ratings = cls.calculate_ratings()

            logger.info("Looks like day just started - no new ratings yet. Do async cleanup.")                        
            #TODO: clean up yesterdays rating
        return ratings
            
            
            
            
            
            
            
    @classmethod
    def get_spot_rating_by_id(cls, region_id, spot_id):
        spot_rating_id = "%s_%s"%(region_id, spot_id)
        spot_rating = ndb.Key.from_path("SpotRaiting", spot_rating_id)
        spot_rating.valid_date = datetime.datetime.today()
        if not spot_rating:
            #TODO select all spot statuses and calculate rating???
            # all this method is not good - may be it's better to perform SpotRaiting creation
            # only while adding status?
            spot_rating = cls(id = id, region_id = region_id, spot_id = spot_id)
      
        
        
        
        
        
        
        