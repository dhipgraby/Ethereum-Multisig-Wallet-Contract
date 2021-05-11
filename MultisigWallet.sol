pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

contract MultisigWallet {
 
   struct wallet {
        uint8 signatures;
        uint walletBalance;
        address[] members;
    }
    
      struct transaction {
        uint256 amount;
        address payable to;
        bool signed;
    }

    uint walletId = 0;
    uint transactionCounter = 0;
    uint public membersLimit = 10;
 
    /******* MAPPINGS ********/
    
    mapping(uint => wallet) public userWallet;

    //Return all wallets from a owner address (member => wallets[])
    mapping(address => uint[]) private allWallets;
    mapping(uint => mapping(address => bool)) public approved;
    //Wallet id to => transaction number to => transaction
    mapping(uint => mapping(uint => transaction)) public walletTransaction;
    
    /******* MODIFIERS ********/
    
    //Check that all members are different
    modifier membersValidation(address[] memory _addresses){
      bool chekcAddr;  
      for(uint i = 0; i < _addresses.length;i++){
      for(uint y = i+1; y < _addresses.length;y++){
        if(_addresses[i] == _addresses[y]) chekcAddr = true;
      }
      }  
      require(chekcAddr == false,"All addresses should be unique");
        _;
    }
    
    //Action for members of a wallet
    modifier onlyWalletMember(uint _walletId){
      address member = msg.sender;    
      bool isMember; 
      address[] memory members = membersFromWallet(_walletId);
      require(members.length > 1,"There is no members in this wallet");
      
      for(uint i = 0; i < members.length;i++){
         
         if(members[i] == member) isMember = true;
         
      }  
      
      require(isMember == true,"You are not a member of this wallet");
        _;
    }

     modifier isWalletMember(address member,uint _walletId){
      
      bool isMember; 
      address[] memory members = membersFromWallet(_walletId);
      require(members.length > 1,"There is no members in this wallet");
      
      for(uint i = 0; i < members.length;i++){
         
         if(members[i] == member) isMember = true;
         
      }  
      require(isMember == true,"Address not belong to this wallet");
        _;
    }
    
    modifier walletExist(uint _walletId){
      
      bool isMember; 
      address[] memory members = membersFromWallet(_walletId);
      require(members.length > 1,"There is no members in this wallet");
        _;
    }
    
    modifier isValidTransaction(uint _walletId,uint _trasactionId){
         require(walletTransaction[_walletId][_trasactionId].to != address(0),"Invalid transaction id");
         require(walletTransaction[_walletId][_trasactionId].signed != true,"Trasaction already aprroved");
         _;
      }
    
    /******* EVENTS *******/
    
    event walletCreated(uint _walletId);
    event depositReceived(uint _walletId,uint _amount,address _from);
    event transactionCreated(uint _walletId,uint _amount,address _creator,address member);
    event transactionSigned(uint _walletId,uint _trasactionId,address _member);
    event transactionRevoked(uint _walletId,uint _trasactionId,address _member);
    event transactionApproved(uint _walletId,uint _trasactionId);
    event walletWithdrawal(uint _walletId,uint _trasactionId);
    
    /******* MAIN FUNCTIONS ********/
    
    function createWallet(address[] memory _addresses,uint8 _signatures) public membersValidation(_addresses) {
    
        require(_addresses.length > 1,"You need at least two members to create a wallet");
        require(_addresses.length <= 10,"Limit is max 10 users per wallet");
        require(_signatures > 0,"You need at least one signature to create a wallet");
        require(_signatures <= _addresses.length,"Signatures should be equal or less than number or members");
        walletId += 1;
        
        userWallet[walletId].members = _addresses;
        userWallet[walletId].walletBalance = 0;
        userWallet[walletId].signatures = _signatures;
        allWallets[msg.sender].push(walletId);
        
        emit walletCreated(walletId);
    }
    
    //Wrapper for getAllWallets mapping
    
    function getWallets(address _owner) public view returns(uint[] memory){
        return(allWallets[_owner]);
    }
    
    // Wrapper for userWallet.members - Return all members from a wallet
    
    function membersFromWallet(uint _walletId) public view returns(address[] memory members) {
        return(userWallet[_walletId].members);
    }
    
    function depositToWallet(uint _walletId) public payable
    onlyWalletMember(_walletId)
    walletExist(_walletId) 
    returns(bool){
     
     require(msg.value > 0,"Deposit require some amount");
     uint oldBalance = userWallet[_walletId].walletBalance;
     userWallet[_walletId].walletBalance += msg.value;
     assert(userWallet[_walletId].walletBalance > oldBalance);
     emit depositReceived(_walletId,msg.value,msg.sender);
     return true;
        
    }
    
    function createTransaction(uint _walletId,uint _amount,address payable _to)
    public
    onlyWalletMember(_walletId)
    isWalletMember(_to,_walletId)
    returns(uint transactionId)
    {
        
        uint walletBalance = userWallet[_walletId].walletBalance;
        require(_amount <= walletBalance,"Not enough balance in this wallet");
        
        transactionCounter += 1;
        
        walletTransaction[_walletId][transactionCounter].amount = _amount;
        walletTransaction[_walletId][transactionCounter].to = _to;
        emit transactionCreated(_walletId,_amount,msg.sender,_to);
        return transactionCounter;    
    
    }
    
    function signTransaction(uint _walletId,uint _trasactionId)
    public
    onlyWalletMember(_walletId)
    isValidTransaction(_walletId,_trasactionId)
    {
        require(approved[_trasactionId][msg.sender] != true,"You already signed this transaction");
        approved[_trasactionId][msg.sender] = true;
        emit transactionSigned(_walletId,_trasactionId,msg.sender);
        
        if(checkSignatures(_walletId, _trasactionId) == 0){
            
           walletTransaction[_walletId][_trasactionId].signed = true;
           emit transactionApproved(_walletId,_trasactionId);
        
        }
    }
    
    function revokeSignature(uint _walletId,uint _trasactionId)
    public
    onlyWalletMember(_walletId)
    {
        require(walletTransaction[_walletId][_trasactionId].to != address(0),"Invalid transaction id");
        require(approved[_trasactionId][msg.sender] == true,"Transaction not signed");
        approved[_trasactionId][msg.sender] = false;
        emit transactionRevoked(_walletId,_trasactionId,msg.sender);
        if(checkSignatures(_walletId, _trasactionId) != 0){
            
           walletTransaction[_walletId][_trasactionId].signed = false;
        
        }
    }
    
    function checkSignatures(uint _walletId,uint _trasactionId) 
    public
    view
    onlyWalletMember(_walletId)
    returns(uint signaturesLeft)
    {
      uint requiredSignatures = userWallet[_walletId].signatures;
      
      address[] memory members = membersFromWallet(_walletId);
      
      for(uint i = 0; i < members.length;i++){
         if(requiredSignatures == 0) return requiredSignatures;
         if(approved[_trasactionId][members[i]] == true){
             requiredSignatures--;
         }
         
      }  
      return requiredSignatures;
    
    }
    
    function sendTransaction(uint _walletId,uint _trasactionId)
    public
    onlyWalletMember(_walletId)
    returns(bool)
    {
        
        require(walletTransaction[_walletId][_trasactionId].signed == true,"Not enough signatures to send this transaction");
        require(walletTransaction[_walletId][_trasactionId].to != address(0),"Invalid transaction id");
        
        uint _amount = walletTransaction[_walletId][_trasactionId].amount;
        address payable member = walletTransaction[_walletId][_trasactionId].to;
        
        if(withdrawFromWallet(_walletId,_amount,member) != true) return false;
        emit walletWithdrawal(_walletId,_trasactionId);
        return true;
        
    }

    function withdrawFromWallet(uint _walletId,uint _amount,address payable member)
    private
    returns(bool)
    {
        uint oldBalance = userWallet[_walletId].walletBalance;
        require(_amount <= oldBalance,"Not enough balance in this wallet");
        userWallet[_walletId].walletBalance -= _amount;
        assert(userWallet[_walletId].walletBalance < oldBalance);
        member.transfer(_amount);
        return true;    
        
    }
}