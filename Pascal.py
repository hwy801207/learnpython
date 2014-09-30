#!/usr/bin/env python
#coding=utf-8
"""打印帕斯卡三角"""

p = []
def Pascal(line):
    """
    下一行的元素是上一行元素的前后之和，如果前面的元素
    不存在，就用0 替代. 所以头跟尾需要特殊处理
    """
    tmp = []
    if line == 1:
        tmp = [1]
        p.append(tmp)
    else:
        pre = Pascal(line-1)[-1]
        for i in range(line):
            if i == 0:
                tmp.append(pre[i] + 0)
            elif i == line - 1:
                tmp.append(pre[i-1] + 0)
            else:
                tmp.append(pre[i-1]+ pre[i])
        p.append(tmp)
    return p

# add a new line to file
Pascal(6)
for i in p:
    f = str(i).center(len(str(p[-1])))
    print f.replace(',', ' ').replace('[', '').replace(']', '')
# Add end of file
