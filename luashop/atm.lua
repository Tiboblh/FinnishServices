local bank = peripheral.find("numismatics_bank_terminal")

for _, uuid in ipairs(bank.getAccounts()) do
    print(textutils.serialize(bank.isPlayerOwned(uuid )) .. ": " .. bank.getAccountLabel(uuid).. ": " .. bank.getBalance(uuid))
    sleep(0.1)
end