with open('my_file.txt') as file:
    data = file.readlines()
for line in data:
    spliting_content = line.split()
    print(spliting_content)
