import requests

NAME = 'sample-function'

def handler(event, context):
    print(NAME)
    