my_dic = {'name':'Anil','age':'27','city':'Dvg'}
my_dic['occupation']='Devops'
#print(my_dic['name'])
my_dic['age']='26'
#del my_dic['occupation']
if 'email' in my_dic:
    print("age is present in dictionary")
else:
    print("The value is not present in dictionary")
for key,value in my_dic.items():
    print(key,value)
print(my_dic)