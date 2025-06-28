import { useState } from 'react';
import { ethers } from 'ethers';
import CityManagerABI from './../CityManagerABI.json'; 
import './App.css';


const CONTRACT_ADDRESS = "0x1ed5e4117958597D6Bd4c4426C37B4F1f0dEa267";

function App() {
  const [playerAddress, setPlayerAddress] = useState(null);
  const [contract, setContract] = useState(null);
  const [cityData, setCityData] = useState(null);
  const [txStatus, setTxStatus] = useState("");

  const connectWallet = async () => {
    if (typeof window.ethereum !== 'undefined') {
      try {
        setTxStatus("Connecting to wallet...");
        const provider = new ethers.providers.Web3Provider(window.ethereum);
        await provider.send("eth_requestAccounts", []);
        
        const signer = provider.getSigner();
        const address = await signer.getAddress();
        setPlayerAddress(address);

        // Naye ABI variable ko yahan use karein
        const contractInstance = new ethers.Contract(CONTRACT_ADDRESS, CityManagerABI, signer);
        setContract(contractInstance);

        setTxStatus("Wallet Connected. Please ensure you are on the Sepolia Network.");
      } catch (error) {
        console.error("Error connecting wallet:", error);
        setTxStatus("Connection failed.");
      }
    } else {
      alert("Please install MetaMask!");
    }
  };

  const fetchCityData = async () => {
    if (contract && playerAddress) {
      try {
        setTxStatus("Fetching city data...");
        const data = await contract.cities(playerAddress);
        if(data.turn.toString() === "0") {
          setTxStatus("Game not started for this account. Click 'Start New Game'.");
          setCityData(null);
        } else {
          setCityData(data);
          setTxStatus("Data fetched!");
        }
      } catch (error) {
        console.error("Could not fetch city data:", error);
        setTxStatus("Failed to fetch data. Are you on the Sepolia network?");
      }
    }
  };
  
  const handleStartGame = async () => {
      if(contract) {
          try {
              setTxStatus("Sending startGame transaction...");
              const tx = await contract.startGame();
              await tx.wait();
              setTxStatus("Game Started! Fetching new data...");
              fetchCityData();
          } catch (error) {
              console.error("Could not start game:", error);
              setTxStatus(`Start game failed: ${error.reason || 'Check console'}`);
          }
      }
  }

  const handleBuild = async (buildingType) => {
    if(contract) {
      let buildingName;
      if (buildingType === 0) buildingName = "Residential";
      if (buildingType === 1) buildingName = "Factory";
      if (buildingType === 2) buildingName = "Power Plant";
      
      try {
        setTxStatus(`Building ${buildingName}...`);
        const tx = await contract.buildStructure(buildingType);
        await tx.wait();
        setTxStatus(`${buildingName} built! Fetching new data...`);
        fetchCityData();
      } catch (error) {
        console.error("Could not build:", error);
        setTxStatus(`Build failed: ${error.reason || 'Check console'}`);
      }
    }
  }

  return (
    <div className="App">
      <header className="App-header">
        <h1>Cross-Chain City Manager</h1>
        {playerAddress ? (
          <div>
            <p className="address-display">Connected: {playerAddress.substring(0, 6)}...{playerAddress.substring(playerAddress.length - 4)}</p>
            
            {!cityData ? (
              <button onClick={handleStartGame}>Start New Game</button>
            ) : (
              <button onClick={fetchCityData}>Refresh City Data</button>
            )}

            {cityData && (
              <div className='city-data-display'>
                <h3>Your City Status:</h3>
                <p>Turn: {cityData.turn.toString()} / 10</p>
                <p>Wood: {cityData.wood.toString()}</p>
                <p>Steel: {cityData.steel.toString()}</p>
                <p>Energy: {cityData.energy.toString()}</p>
                <p>Residential: {cityData.residential.toString()}</p>
                <p>Factory: {cityData.factory.toString()}</p>
                <p>Power Plant: {cityData.powerPlant.toString()}</p>
              </div>
            )}
            
            {cityData && cityData.turn > 0 && cityData.turn <= 10 && (
              <div className='build-actions'>
                <h3>Build Actions:</h3>
                <button onClick={() => handleBuild(0)}>Build Residential (100W, 50S)</button>
                <button onClick={() => handleBuild(1)}>Build Factory (200S, 100E)</button>
                <button onClick={() => handleBuild(2)}>Build Power Plant (150W, 100E)</button>
              </div>
            )}

            {cityData && cityData.turn > 10 && (
              <div>
                <h3>Game Over!</h3>
                <p>You completed 10 turns. Check your final score.</p>
              </div>
            )}
            
            <p>Status: {txStatus}</p>

          </div>
        ) : (
          <button onClick={connectWallet} className="connect-button">
            Connect Wallet
          </button>
        )}
      </header>
    </div>
  );
}

export default App;