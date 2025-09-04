from vetiver import VetiverModel
from vetiver import VetiverAPI
from pins import board_folder

## Get the pinned model
b = board_folder('./data/model', allow_pickle_read = True)
v = VetiverModel.from_pin(b, 'penguin_model')

## Turn model into an API
app = VetiverAPI(v, check_prototype = True)

## Run the API
app.run(port = 8080)
