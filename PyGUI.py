import PySimpleGUI as sg
from NewInstall import test

layout = [  [sg.Checkbox('', default=False, key="-TEST-"), sg.Text('Настроить репозиторий')],
            [sg.Button('Ok'), sg.Button('Quit')] ]

window = sg.Window('Window Title', layout)

while True:
    event, values = window.read()
    # See if user wants to quit or window was closed
    if event == sg.WINDOW_CLOSED or event == 'Quit':
        break
    elif values["-TEST-"] == True: test()

# Finish up by removing from the screen
window.close()