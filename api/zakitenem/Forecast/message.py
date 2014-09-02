# Have to place all the messages' classes to the same file to make generated Objective C classes 
# names shorter

from protorpc import messages, message_types
import ConfigParser
import datetime

#It is a fundamental limitation: never more then 10 forecasts according to windguru rules
forecast_max_count = 10

class Spot(messages.Message):
    id = messages.StringField(1)
    
    name = messages.StringField(2)
    url = messages.StringField(3)
    forecast = messages.StringField(4)
    
    latitude = messages.FloatField(5)
    longitude = messages.FloatField(6)
    
    default_rating = messages.IntegerField(7)
    
class SpotList(messages.Message):
    spots = messages.MessageField(Spot, 1, repeated = True)
    next_update_time = message_types.DateTimeField(2)
    
def region_spots(region_id, next_update_time=None):
    config_file='./resources/%s.cfg'%region_id
    parser = ConfigParser.RawConfigParser()
    parser.read(config_file)
    spot_list = list()
    for section in parser.sections():
        spot = Spot()
        spot.id = section
        spot.name = parser.get(section, "name").decode('utf-8')
        with open('./resources/Forecasts/%s.html'%section, 'r') as forecast_file:
            spot.forecast = forecast_file.read() 
             
        if parser.has_option(section, "latitude"):
            spot.latitude = float(parser.get(section, "latitude"))
            spot.longitude = float(parser.get(section, "longitude"))
        
        spot.default_rating = int(parser.get(section, "default_rating"))
        spot_list.append(spot)

    spot_list.sort(key=lambda x:x.default_rating, reverse=True)
    if len(spot_list) > forecast_max_count:
        spot_list_end = len(spot_list) - forecast_max_count
        spot_list = spot_list[:-spot_list_end]

    #If next_update_time in't set use current time +1 minute
    if (not next_update_time):
        next_update_time = datetime.datetime.now() + datetime.timedelta(minutes=1)  
    return SpotList(spots=spot_list, next_update_time=next_update_time)

