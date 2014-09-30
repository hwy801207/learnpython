#!/usr/bin/env python
# -*- coding:utf-8 -*-

def weightGrade(grades, weights=(0.3, 0.3, 0.4)):
    result = (grades[0] * weights[0]) +\
             (grades[1] * weights[1]) +\
             (grades[2] * weights[2])
    return result

def grade(line):
    tmp = line.split(',')
    name = tmp[1].strip() + ' ' + tmp[0].strip()
    grades=[]
    for item in tmp[2:]:
        grades.append(int(item))
    result = weightGrade(grades)
    return name, result 

def main():
    prompt = "Please input a file include the grades: "
    fileName = raw_input(prompt)
    fileFd = open(fileName)
    print "%-15s  %-15s" %("Name", "Result")
    print "-" * 25
    for line in fileFd:
        line = line.strip()
        print "%-15s %7.2f" % grade(line)

if __name__ == '__main__':
    main()
    


