import React from 'react';
import { Connect } from '@stacks/connect-react';
import NaijaTransferApp from './components/NaijaTransferApp';

const App = () => {
  return (
    <Connect
      authOptions={{
        appDetails: {
          name: 'Naija Transfer',
          icon: '/logo.png',
        },
        redirectTo: '/',
        onFinish: () => {
          window.location.reload();
        },
      }}
    >
      <NaijaTransferApp />
    </Connect>
  );
};

export default App;