import { useCallback } from 'react';
import { useConnect } from '@stacks/connect-react';
import { StacksMainnet } from '@stacks/network';

const useContractCall = () => {
  const { doContractCall } = useConnect();

  const callContract = useCallback(
    async (functionName, functionArgs) => {
      return doContractCall({
        network: new StacksMainnet(),
        anchorMode: 1,
        contractAddress: process.env.REACT_APP_CONTRACT_ADDRESS,
        contractName: process.env.REACT_APP_CONTRACT_NAME,
        functionName,
        functionArgs,
        postConditionMode: 1,
        onFinish: data => {
          console.log('Contract call finished:', data);
        },
      });
    },
    [doContractCall]
  );

  return callContract;
};

export default useContractCall;
