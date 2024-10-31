# Naija Transfer

## Overview

Naija Transfer is a decentralized remittance platform built on the Stacks blockchain, created to facilitate cost-effective transfers from Nigerians living abroad back to Nigeria. This project focuses on offering a secure, streamlined, and economical solution for the Nigerian diaspora to send money home.

## Features

- User account setup with Nigerian bank details
- STX (Stacks cryptocurrency) deposit functionality
- Remittance sending with auto-calculated fees
- Exchange rate management with real-time updates
- Withdrawal function (integrated with off-chain processes)
- Balance inquiries and retrieval of user details

## Technology Stack

- **Smart Contract**: Clarity (on the Stacks blockchain)
- **Frontend**: React.js
- **Backend**: Node.js
- **Blockchain Interaction**: Stacks.js

## Smart Contract

The foundation of Naija Transfer is a Clarity smart contract deployed on the Stacks blockchain. Key functions include:

- `register-user`: Registers users with their name and Nigerian bank account details
- `deposit`: Allows users to fund their account with STX
- `send-remittance`: Transfers funds between registered users
- `withdraw`: Initiates fund withdrawal to a Nigerian bank account
- `get-balance`: Provides a user’s account balance
- `get-exchange-rate`: Returns the current STX to Naira exchange rate

## How to Use

1. **Setup**:
   - Clone this repository
   - Install dependencies for both frontend and backend
   - Set up environment variables

2. **Smart Contract Deployment**:
   - Deploy the Clarity smart contract to the Stacks blockchain (begin with testnet, then move to mainnet)

3. **Running the Application**:
   - Start the backend server
   - Launch the frontend interface

4. **User Journey**:
   - Register an account
   - Connect your Stacks wallet
   - Deposit STX into your account
   - Send remittances to registered Nigerian recipients
   - Withdraw funds to a Nigerian bank account linked to your profile

## Development

To contribute to Naija Transfer:

1. Fork this repository
2. Create a branch for your feature
3. Commit your modifications
4. Push to your branch
5. Submit a Pull Request

## Security Considerations

- A comprehensive security audit is recommended before mainnet deployment
- Educate users on secure key management practices
- Ensure exchange rates are frequently updated for accurate conversions

## Regulatory Compliance

Naija Transfer is committed to adhering to Nigerian financial regulations. Users must ensure their use of the platform complies with local laws regarding cross-border money transfers.

## Future Enhancements

- Integration with additional Nigerian banks for direct transfers
- Support for a range of cryptocurrencies
- Mobile application for easier access
- A decentralized exchange rate oracle

## Disclaimer

Naija Transfer is a prototype and should not be used for actual financial transactions without proper legal and financial consultation. The creators are not liable for any loss of funds or legal implications from using this platform.

