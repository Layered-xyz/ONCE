# Layered ONCE (ON-Chain Entity)

ONCE is the base layer for building on chain entities.

ONCE is a contract system that allows you to build any on-chain entity with maximum flexibility to add and remove functionality & capabilities as you grow. 

With ONCE you can build your organization as a single signer smart account, upgrade to a multi-sig once you get funding, and then upgrade to a DAO or multi-domain at any future date all while maintaining the security that is core to operating your organization on chain. 

You can also build tokens and other common contracts with modular functionality. For example you may build an ERC-721 token and change the minting mechanism over time (ie. Allowlist -> Token-gated -> Open minting). Or you may build an ERC-20 token and decide to make it non-transferrable at a later date.

ONCE contracts can also be locked to make them immutable allowing a community or organization to create their organization on ONCE, modify it to their growing needs, and then lock it at a later date. 

ONCE is...
- Maximally flexible and customizable to your organization
- Fully secure
- Open-source & actively supported by the team at Layered
- Designed to work with existing robust solutions and UI layers like Safe, Governor, Tally.xyz, Opensea, etc.

ONCE is not...
- A competitor or replacement for existing industry-standard solutions like Gnosis Safe -- _ONCE actually allows you to build a Safe on top of ONCE for maximum flexibility without sacrificing security!_

### How it works
ONCE is a permissioned proxy system inspired by the [EIP-2535 Diamond Standard](https://github.com/ethereum/EIPs/issues/2535) that is used to create a modular smart contract system for on-chain entities.

ONCE leverages plugins (similar to the diamond standard's 'facets') to allow you to customize the functionality of your on chain entity depending on your needs.

Currently the most common use case for ONCE is building an "evolving" organization that can grow from a single signer account to a multi-sig to a DAO.

Plugins for ONCE can be built by anyone and follow a simple interface to allow you to further customize your on-chain entity to serve the exact needs of your organization. Currently the Layered team is building out the most commonly used plugins. Please see our roadmap for more information on upcoming plugins and reach out to jay@layered.xyz for any requested functionality. 

## License

MIT license. See the license file.
Anyone can use or modify this software for their purposes.

