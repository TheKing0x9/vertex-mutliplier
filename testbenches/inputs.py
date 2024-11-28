import numpy as np
import math
def float16decimaltobinary(value):
    if value==0:
        return "0000000000000000"
    signbit='0'
    if value<0:
        signbit='1'
        value=(-value)
    fractionalpart,integerpart=math.modf(value)
    integerpart=int(integerpart)
    binary_of_integer_part=bin(integerpart)[2:]
    binary_of_fraction_part=""
    for i in range(40):
        fractionalpart*=2
        if fractionalpart>=1:
            fractionalpart-=1
            binary_of_fraction_part+='1'
        else:
            binary_of_fraction_part+='0'
    finalbinaryvalue=binary_of_integer_part+'.'+binary_of_fraction_part
    decimali=-1
    onei=-1
    for i in range(len(finalbinaryvalue)):
        if decimali==-1 and finalbinaryvalue[i]=='.':
            decimali=i
        if onei==-1 and finalbinaryvalue[i]=='1':
            onei=i
        if decimali!=-1 and onei!=-1:
            break
    # print(onei)
    # print(decimali)
    if onei>decimali:
        exponent=decimali-onei+15
    else:
        exponent=decimali-onei+14
    exponentbits=bin(exponent)[2:].zfill(5)
    mantissabits=""
    for i in range(onei+1,len(finalbinaryvalue)):
        if(len(mantissabits)==10):
            break
        if finalbinaryvalue[i]!='.':
            mantissabits+=finalbinaryvalue[i]
    # print(finalbinaryvalue)
    finalvalue=signbit+exponentbits+mantissabits
    return finalvalue
def float16binarytodecimal(value):
    if value=="0000000000000000":
        return 0
    exponent=value[1:6]
    mantissa='1'+value[6:]
    actualexponent=int(exponent,2)-15
    actualmantissa=int(mantissa,2)
    finalvalue=(2**(actualexponent-10))*actualmantissa
    if value[0]=='1':
        finalvalue=-finalvalue
    return finalvalue
def matmul(a,b):
    c=[0,0,0,0]
    c[0]=a[0][0]*b[0]+a[0][1]*b[1]+a[0][2]*b[2]+a[0][3]*b[3]
    c[1]=a[1][0]*b[0]+a[1][1]*b[1]+a[1][2]*b[2]+a[1][3]*b[3]
    c[2]=a[2][0]*b[0]+a[2][1]*b[1]+a[2][2]*b[2]+a[2][3]*b[3]
    c[3]=a[3][0]*b[0]+a[3][1]*b[1]+a[3][2]*b[2]+a[3][3]*b[3]
    return c

a=[[2.7695 ,  -4.5886,   -5.9392,  -60.0000],
    [2.5857 ,   8.7379 ,  -5.5451 , -26.6675],
   [-1.8126 ,        0 ,  -0.8452 ,  -1.0000],
   [-0.9063  ,       0 ,  -0.4226  ,  2.5000]]

lines_to_write=[]
for i in range(4):
    for j in range(4):
        lines_to_write.append(float16decimaltobinary(a[i][j])+'\n')
obtainedoutputs=[]
expectedoutputs=[]
with open("teapot.data", "r") as file:
    for line in file:
        point=line.strip().split("  ")
        x=float(point[0])
        y=float(point[1])
        z=float(point[2])
        w=float('1')
        ox,oy,oz,ow=matmul(a,[x,y,z,w])
        expectedoutputs.append(str(ox)+'\n')
        expectedoutputs.append(str(oy)+'\n')
        expectedoutputs.append(str(oz)+'\n')
        expectedoutputs.append(str(ow)+'\n')
        lines_to_write.append(float16decimaltobinary(x)+'\n')
        lines_to_write.append(float16decimaltobinary(y)+'\n')
        lines_to_write.append(float16decimaltobinary(z)+'\n')
        lines_to_write.append(float16decimaltobinary(w)+'\n')

with open("binarydata.txt", "w") as file:
    file.writelines(lines_to_write)
with open("binarydata2.txt", "r") as file:
    for line in file:
        obtainedoutputs.append(str(float16binarytodecimal(line.strip()))+'\n')
with open("obtainedoutputs.txt", "w") as file:
    file.writelines(obtainedoutputs)
with open("expectedoutputs.txt", "w") as file:
    file.writelines(expectedoutputs)
