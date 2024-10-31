import React, { useState, useEffect } from 'react';
import { fetchTransactions } from '../utils/helpers';

const TransactionHistory = ({ userData }) => {
  const [transactions, setTransactions] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const loadTransactions = async () => {
      try {
        const txs = await fetchTransactions(userData.profile.stxAddress);
        setTransactions(txs);
      } catch (error) {
        console.error('Error fetching transactions:', error);
      } finally {
        setLoading(false);
      }
    };

    loadTransactions();
  }, [userData]);

  if (loading) return <div>Loading transactions...</div>;

  return (
    <div className="transaction-history-container">
      <h2>Transaction History</h2>
      <ul>
        {transactions.map((tx, index) => (
          <li key={index}>
            <p>Type: {tx.type}</p>
            <p>Amount: {tx.amount} STX</p>
            <p>Status: {tx.status}</p>
            <p>Date: {new Date(tx.timestamp * 1000).toLocaleString()}</p>
          </li>
        ))}
      </ul>
    </div>
  );
};

export default TransactionHistory;
