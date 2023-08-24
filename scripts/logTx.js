import { ethers } from "ethers"
import { config } from "dotenv"

config();

const ALERT_THRESHOLD = ethers.utils.parseEther("10");

const main = async () => {
    const provider = new ethers.providers.WebSocketProvider(`https://eth-mainnet.g.alchemy.com/v2/${process.env.API_KEY}`);
    provider.on("pending", async (tx) => {
        try { 
            const txData = await provider.getTransaction(tx);
            if (txData && txData.value.gte(ALERT_THRESHOLD)) {
                console.log("tx value: ", txData.value);
                console.log("threshold: ", ALERT_THRESHOLD, "\n");
            }
        } catch {}
    })
}

main();