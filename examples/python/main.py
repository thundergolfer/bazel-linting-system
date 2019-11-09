# This file has the following linting errors:
# - inline comment too close to source code
# - too many lines between code
import stuff


def main(count):
    print("Hello world " * count) # this comment should be two spaces from end of code
    print(stuff.IMPORT_ME)



if __name__ == "__main__":
    main(5)
