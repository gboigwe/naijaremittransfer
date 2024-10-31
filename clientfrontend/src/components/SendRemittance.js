import React, { useState } from 'react';
import { useConnect } from '@stacks/connect-react';
import { StacksMainnet } from '@stacks/network';
import { contractAddress, contractName } from '../utils/constants';
import useExchangeRate from '../hooks/useExchangeRate';

const SendRemittance = ({ userData }) => {
  const [recipient, setRecipient] = useState('');
  const [amount, setAmount] = useState('');
  const { doContractCall } = useConnect();
  const exchangeRate = useExchangeRate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      await doContractCall({
        network: new StacksMainnet(),
        anchorMode: 1,
        contractAddress,
        contractName,
        functionName: 'send-remittance',
        functionArgs: [recipient, amount],
        postConditionMode: 1,
        onFinish: data => {
          console.log('Remittance sent:', data);
        },
      });
    } catch (e) {
      console.error('Remittance error:', e);
    }
  };

  const nairaAmount = amount && exchangeRate ? (parseFloat(amount) * exchangeRate).toFixed(2) : '0.00';

  return (
    <div className="send-remittance-container">
      <h2>Send Remittance</h2>
      <form onSubmit={handleSubmit}>
        <input
          type="text"
          value={recipient}
          onChange={(e) => setRecipient(e.target.value)}
          placeholder="Recipient Address"
          required
        />
        <input
          type="number"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          placeholder="Amount in STX"
          required
        />
        <p>Estimated amount in Naira: ₦{nairaAmount}</p>
        <button type="submit">Send</button>
      </form>
    </div>
  );
};

export default SendRemittance;
