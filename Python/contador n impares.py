contador = 0
for i in range(1, 10):
    modulo = i%2
    print (str(i) + " % 2 = " + str(modulo))
    if modulo*2 != i:
        contador += 1
print (contador)
