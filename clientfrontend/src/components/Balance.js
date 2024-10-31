import React, { useState, useEffect } from 'react';
import { useConnect } from '@stacks/connect-react';
import { callReadOnlyFunction } from '@stacks/transactions';
import { StacksMainnet } from '@stacks/network';
import { Card, CardHeader, CardContent, Spinner } from '@/components/ui';
import { contractAddress, contractName } from '../utils/constants';
import useExchangeRate from '../hooks/useExchangeRate';

const Balance = ({ userData }) => {
  const { doContractCall } = useConnect();
  const [balance, setBalance] = useState(null);
  const [loading, setLoading] = useState(true);
  const exchangeRate = useExchangeRate();

  useEffect(() => {
    const fetchBalance = async () => {
      try {
        const result = await callReadOnlyFunction({
          contractAddress,
          contractName,
          functionName: 'get-balance',
          functionArgs: [userData.profile.stxAddress],
          network: new StacksMainnet(),
        });
        setBalance(parseInt(result.value));
      } catch (error) {
        console.error('Error fetching balance:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchBalance();
  }, [userData]);

  const formatSTX = (amount) => {
    return (amount / 1000000).toFixed(6);
  };

  const formatNaira = (amount) => {
    return (amount * exchangeRate / 1000000).toFixed(2);
  };

  return (
    <Card>
      <CardHeader>Your Balance</CardHeader>
      <CardContent>
        {loading ? (
          <Spinner />
        ) : (
          <div className="space-y-2">
            <p className="text-3xl font-bold">{formatSTX(balance)} STX</p>
            <p className="text-xl text-gray-600">≈ ₦{formatNaira(balance)}</p>
          </div>
        )}
      </CardContent>
    </Card>
  );
};

export default Balance;
