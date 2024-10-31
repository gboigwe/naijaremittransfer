import { useState, useEffect } from 'react';
import { callReadOnlyFunction } from '@stacks/transactions';
import { StacksMainnet } from '@stacks/network';
import { contractAddress, contractName } from '../utils/constants';

const useExchangeRate = () => {
  const [exchangeRate, setExchangeRate] = useState(null);

  useEffect(() => {
    const fetchExchangeRate = async () => {
      try {
        const result = await callReadOnlyFunction({
          contractAddress,
          contractName,
          functionName: 'get-exchange-rate',
          network: new StacksMainnet(),
        });
        setExchangeRate(parseInt(result.value));
      } catch (e) {
        console.error('Error fetching exchange rate:', e);
      }
    };

    fetchExchangeRate();
    const interval = setInterval(fetchExchangeRate, 60000); // Update every minute
    return () => clearInterval(interval);
  }, []);

  return exchangeRate;
};

export default useExchangeRate;
