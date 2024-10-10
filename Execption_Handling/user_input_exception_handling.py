import os
folders = input("Please enter the folders separated by spaces").split()
for folder in folders:
    try:
        files = os.listdir(folder)
        print("Listing the files and directory of",folder,"folder")
        for file in files:
          print(file)
    except FileNotFoundError:
       print("The entered directory is not exists",folder)
       break

