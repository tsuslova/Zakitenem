# Have to place all the messages' classes to the same file to make generated Objective C classes 
# names shorter

from protorpc import messages

class Forecast(messages.Message):
    login = messages.StringField(1)
    
    email = messages.StringField(2)
    phone = messages.StringField(3)
    
    gender = messages.BooleanField(4)
    password = messages.StringField(5)
    
    userpic = messages.StringField(6)
    region = messages.StringField(7)
    subscription_end_date = messages.StringField(8) 
     
    #session = messages.MessageField(Session, 9)
    