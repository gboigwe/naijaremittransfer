export const fetchTransactions = async (address) => {
    const response = await fetch(`https://stacks-node-api.mainnet.stacks.co/extended/v1/address/${address}/transactions`);
    const data = await response.json();
    return data.results.map(tx => ({
      type: tx.tx_type,
      amount: tx.token_transfer ? tx.token_transfer.amount : '0',
      status: tx.tx_status,
      timestamp: tx.burn_block_time,
    }));
  };
  
  export const formatSTX = (amount) => {
    return (parseInt(amount) / 1000000).toFixed(6);
  };
