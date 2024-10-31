import React from 'react';
import { useConnect } from '@stacks/connect-react';

const Header = ({ userData, onSignOut, setCurrentView }) => {
  const { doOpenAuth } = useConnect();

  return (
    <header className="header">
      <h1>Naija Transfer</h1>
      <nav>
        {userData ? (
          <>
            <button onClick={() => setCurrentView('balance')}>Balance</button>
            <button onClick={() => setCurrentView('send')}>Send</button>
            <button onClick={() => setCurrentView('history')}>History</button>
            <button onClick={onSignOut}>Sign Out</button>
          </>
        ) : (
          <button onClick={doOpenAuth}>Connect Wallet</button>
        )}
      </nav>
    </header>
  );
};

export default Header;
