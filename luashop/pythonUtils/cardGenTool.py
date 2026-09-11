# this makes a random gift card number, to be sent to server
import hashlib
import random


class CardGen():
    def makeNums(self):
        self.rawNum1 = random.randint(-2147483648, 2147483647)
        self.rawNum2 = random.randint(-2147483648, 2147483647)
        self.rawNum3 = random.randint(-2147483648, 2147483647)
        self.rawNum4 = random.randint(-2147483648, 2147483647)
        self.rawNum5 = random.randint(-2147483648, 2147483647)
    @staticmethod
    def hash(toHash=str): #thing to hash n stuff
        return hashlib.sha256(toHash.encode("utf-8")).hexdigest()

    @staticmethod
    def combineHash(input=list): #combine all input hashes into 1 final hash
        combined = ""
        for i in input:
            combined += i
        return hashlib.sha256(combined.encode("utf-8")).hexdigest()

    @staticmethod
    def cutChars(s, length): #cut str to just the first chars up to len
        return s[:length]
if __name__ == "__main__":
    while True:
        cg = CardGen()
        cg.makeNums()
        hashedNums = []
        hashedNums.append(CardGen.hash(str(cg.rawNum1)))
        hashedNums.append(CardGen.hash(str(cg.rawNum2)))
        hashedNums.append(CardGen.hash(str(cg.rawNum3)))
        hashedNums.append(CardGen.hash(str(cg.rawNum4)))
        hashedNums.append(CardGen.hash(str(cg.rawNum5)))
        cutHashes = []
        for i in hashedNums:
            cutHashes.append(CardGen.cutChars(i, 4))
        combined = CardGen.combineHash(cutHashes)
        final = CardGen.cutChars(combined, 16)
        # store without dashes
        with open('./cards.txt', 'a', encoding='utf-8') as f:
            f.write(final + "\n")
        # print with dashes: XXXX-XXXX-XXXX-XXXX
        dashed = '-'.join([final[i:i+4] for i in range(0, 16, 4)])
        print(f"code: {dashed}")
        again = input("Generate another? (y/n): ").strip().lower()
        if again != 'y':
            break