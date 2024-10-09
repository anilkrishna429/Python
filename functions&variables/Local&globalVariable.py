x = 5
def my_local_global_variable():
    a = 10
    b = 5
    result = a + b + x
    print("The value of a and b and x is: ",result)
my_local_global_variable()
print(x)