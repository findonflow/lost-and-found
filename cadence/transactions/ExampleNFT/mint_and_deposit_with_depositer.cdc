import FlowToken from "../../contracts/FlowToken.cdc"
import FungibleToken from "../../contracts/FungibleToken.cdc"
import ExampleNFT from "../../contracts/ExampleNFT.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import MetadataViews from "../../contracts/MetadataViews.cdc"

import LostAndFound from "../../contracts/LostAndFound.cdc"

transaction(recipient: Address) {
    // local variable for storing the minter reference
    let minter: &ExampleNFT.NFTMinter
    let depositer: &LostAndFound.Depositer

    prepare(acct: AuthAccount) {
        // borrow a reference to the NFTMinter resource in storage
        self.minter = acct.borrow<&ExampleNFT.NFTMinter>(from: /storage/exampleNFTMinter)
            ?? panic("Could not borrow a reference to the NFT minter")
        self.depositer = acct.borrow<&LostAndFound.Depositer>(from: LostAndFound.DepositerStoragePath)!

        let flowTokenProviderPath = /private/flowTokenLostAndFoundProviderPath

        if !acct.getCapability<&FlowToken.Vault{FungibleToken.Provider}>(flowTokenProviderPath).check() {
            acct.unlink(flowTokenProviderPath)
            acct.link<&FlowToken.Vault{FungibleToken.Provider}>(
                flowTokenProviderPath,
                target: /storage/flowTokenVault
            )
        }
    }

    execute {
        let token <- self.minter.mintAndReturnNFT(name: "testname", description: "descr", thumbnail: "image.html", royalties: [])
        let display = token.resolveView(Type<MetadataViews.Display>()) as! MetadataViews.Display?
        let memo = "test memo"

        self.depositer.deposit(
            redeemer: recipient,
            item: <-token,
            memo: memo,
            display: display
        )
    }
}
