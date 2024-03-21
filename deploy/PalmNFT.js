module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deployer } = await getNamedAccounts();
    const { deploy } = deployments;

    await deploy('PalmNFT', {
        from: deployer,
        log: true,
        deterministicDeployment: false
    });

};
module.exports.tags = ['PalmNFT'];