import re

f = open('BasicWords.txt', 'r')
text = f.read()
textCSV = ""
for i in text:
    if i == '\r' or i == '\n':
        textCSV += ","
    else:
        textCSV += i

print textCSV
