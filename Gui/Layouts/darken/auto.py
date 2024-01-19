# Define the alpha increment value
increment = 0.01

header = '''<?xml version="1.0" encoding="UTF-8" ?>
<MyGUI type="Layout" version="3.2.0">'''

xml_content = '''
    <Widget type="Widget" skin="BlurryBackgroundSkin" position_real="0 0 1 1" name="blur_box_{EDIT_ME3}">
        <Property key="NeedMouse" value="false" />
        <Property key="NeedKey" value="false" />
        <Property key="Alpha" value="{EDIT_ME}" />
        <Property key="Visible" value="{EDIT_ME2}" />
        <Widget type="ImageBox" skin="ImageBox" name="BackgroundImage" position_real="0 0 1 1">
            <Property key="ImageTexture" value="blank.png" />
        </Widget>
    </Widget>
'''
footer = "</MyGUI>"

new_content = ""

# Increment and replace the placeholder with the new alpha value
alpha = 0.0
while alpha <= 1.0:
    
    formatted_content = xml_content.replace('{EDIT_ME}', f'{alpha:.2f}').replace('{EDIT_ME2}', "false").replace('{EDIT_ME3}', f'{alpha:.2f}'.replace(".", "_"))
    
    new_content += formatted_content + "\n"

    alpha += increment

file_name = f'Gui/Layouts/darken/darken_new.layout'

# Write the formatted content to a new file
with open(file_name, 'w') as file:
    file.write(header+new_content+footer)