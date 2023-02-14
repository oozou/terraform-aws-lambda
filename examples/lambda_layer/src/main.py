import os
import io
import sys
import csv
import requests


def lambda_handler(event, context):
    response = requests.get("https://www.google.com")
    return response.json()
