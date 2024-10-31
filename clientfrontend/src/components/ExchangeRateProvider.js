import React, { useState, useEffect } from 'react';
import { useConnect } from '@stacks/connect-react';
import { StacksMainnet } from '@stacks/network';
import { callReadOnlyFunction } from '@stacks/transactions';
import { contractAddress, contractName } from '../utils/constants';

const ExchangeRateProvider = () => {
  const [exchangeRate, setExchangeRate] = useState(null);
  const { doContractCall } = useConnect();

  useEffect(() => {
    const fetchExchangeRate = async () => {
      try {
        const rateResult = await callReadOnlyFunction({
          contractAddress,
          contractName,
          functionName: 'get-exchange-rate',
          network: new StacksMainnet(),
        });
        setExchangeRate(rateResult.value.toString());
      } catch (e) {
        console.error('Error fetching exchange rate:', e);
      }
    };

    fetchExchangeRate();
    const interval = setInterval(fetchExchangeRate, 60000); // Update every minute
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="exchange-rate-container">
      <h2>Current Exchange Rate</h2>
      {exchangeRate !== null ? (
        <p>1 STX = {exchangeRate} Naira</p>
      ) : (
        <p>Loading exchange rate...</p>
      )}
    </div>
  );
};

export default ExchangeRateProvider;
