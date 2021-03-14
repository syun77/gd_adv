import os

# ルートフォルダ
DIR_ROOT = os.path.dirname(__file__)

def write_cdb_init(filename, key, cnt):
    str = ""

    for i in range(cnt):
        str += "\t\t\t\t{\n"
        str += "\t\t\t\t\t\"id\": \"%s%03d\",\n"%(key, i)
        str += "\t\t\t\t\t\"value\": %d\n"%i
        if i == cnt-1:
            str += "\t\t\t\t}\n"
        else:
            str += "\t\t\t\t},\n"

    #print(str)
    f = open(DIR_ROOT + "/" + filename, "w")
    f.write(str)
    f.close()

write_cdb_init("flag_init.txt", "FLG_", 256)
