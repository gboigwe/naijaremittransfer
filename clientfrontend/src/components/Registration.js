import React, { useState } from 'react';
import { useConnect } from '@stacks/connect-react';
import { StacksMainnet } from '@stacks/network';
import { contractAddress, contractName } from '../utils/constants';

const Registration = ({ userData }) => {
  const [name, setName] = useState('');
  const [bankAccount, setBankAccount] = useState('');
  const { doContractCall } = useConnect();

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      await doContractCall({
        network: new StacksMainnet(),
        anchorMode: 1,
        contractAddress,
        contractName,
        functionName: 'register-user',
        functionArgs: [name, bankAccount],
        postConditionMode: 1,
        onFinish: data => {
          console.log('Registration successful:', data);
        },
      });
    } catch (e) {
      console.error('Registration error:', e);
    }
  };

  return (
    <div className="registration-container">
      <h2>User Registration</h2>
      <form onSubmit={handleSubmit}>
        <input
          type="text"
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder="Full Name"
          required
        />
        <input
          type="text"
          value={bankAccount}
          onChange={(e) => setBankAccount(e.target.value)}
          placeholder="Bank Account Number"
          required
        />
        <button type="submit">Register</button>
      </form>
    </div>
  );
};

export default Registration;
