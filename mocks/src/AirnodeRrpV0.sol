// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

interface IAuthorizationUtilsV0 {
    function checkAuthorizationStatus(
        address[] calldata authorizers,
        address airnode,
        bytes32 requestId,
        bytes32 endpointId,
        address sponsor,
        address requester
    ) external view returns (bool status);

    function checkAuthorizationStatuses(
        address[] calldata authorizers,
        address airnode,
        bytes32[] calldata requestIds,
        bytes32[] calldata endpointIds,
        address[] calldata sponsors,
        address[] calldata requesters
    ) external view returns (bool[] memory statuses);
}

interface IAuthorizerV0 {
    function isAuthorizedV0(bytes32 requestId, address airnode, bytes32 endpointId, address sponsor, address requester)
        external
        view
        returns (bool);
}

/// @title Contract that implements authorization checks
contract AuthorizationUtilsV0 is IAuthorizationUtilsV0 {
    /// @notice Uses the authorizer contracts of an Airnode to decide if a
    /// request is authorized. Once an Airnode receives a request, it calls
    /// this method to determine if it should respond. Similarly, third parties
    /// can use this method to determine if a particular request would be
    /// authorized.
    /// @dev This method is meant to be called off-chain, statically by the
    /// Airnode to decide if it should respond to a request. The requester can
    /// also call it, yet this function returning true should not be taken as a
    /// guarantee of the subsequent request being fulfilled.
    /// It is enough for only one of the authorizer contracts to return true
    /// for the request to be authorized.
    /// @param authorizers Authorizer contract addresses
    /// @param airnode Airnode address
    /// @param requestId Request ID
    /// @param endpointId Endpoint ID
    /// @param sponsor Sponsor address
    /// @param requester Requester address
    /// @return status Authorization status of the request
    function checkAuthorizationStatus(
        address[] calldata authorizers,
        address airnode,
        bytes32 requestId,
        bytes32 endpointId,
        address sponsor,
        address requester
    ) public view override returns (bool status) {
        for (uint256 ind = 0; ind < authorizers.length; ind++) {
            IAuthorizerV0 authorizer = IAuthorizerV0(authorizers[ind]);
            if (authorizer.isAuthorizedV0(requestId, airnode, endpointId, sponsor, requester)) {
                return true;
            }
        }
        return false;
    }

    /// @notice A convenience function to make multiple authorization status
    /// checks with a single call
    /// @param authorizers Authorizer contract addresses
    /// @param airnode Airnode address
    /// @param requestIds Request IDs
    /// @param endpointIds Endpoint IDs
    /// @param sponsors Sponsor addresses
    /// @param requesters Requester addresses
    /// @return statuses Authorization statuses of the request
    function checkAuthorizationStatuses(
        address[] calldata authorizers,
        address airnode,
        bytes32[] calldata requestIds,
        bytes32[] calldata endpointIds,
        address[] calldata sponsors,
        address[] calldata requesters
    ) external view override returns (bool[] memory statuses) {
        require(
            requestIds.length == endpointIds.length && requestIds.length == sponsors.length
                && requestIds.length == requesters.length,
            "Unequal parameter lengths"
        );
        statuses = new bool[](requestIds.length);
        for (uint256 ind = 0; ind < requestIds.length; ind++) {
            statuses[ind] = checkAuthorizationStatus(
                authorizers, airnode, requestIds[ind], endpointIds[ind], sponsors[ind], requesters[ind]
            );
        }
    }
}

interface ITemplateUtilsV0 {
    event CreatedTemplate(bytes32 indexed templateId, address airnode, bytes32 endpointId, bytes parameters);

    function createTemplate(address airnode, bytes32 endpointId, bytes calldata parameters)
        external
        returns (bytes32 templateId);

    function getTemplates(bytes32[] calldata templateIds)
        external
        view
        returns (address[] memory airnodes, bytes32[] memory endpointIds, bytes[] memory parameters);

    function templates(bytes32 templateId)
        external
        view
        returns (address airnode, bytes32 endpointId, bytes memory parameters);
}

/// @title Contract that implements request templates
contract TemplateUtilsV0 is ITemplateUtilsV0 {
    struct Template {
        address airnode;
        bytes32 endpointId;
        bytes parameters;
    }

    /// @notice Called to get a template
    mapping(bytes32 => Template) public override templates;

    /// @notice Creates a request template with the given parameters,
    /// addressable by the ID it returns
    /// @dev A specific set of request parameters will always have the same
    /// template ID. This means a few things: (1) You can compute the expected
    /// ID of a template before creating it, (2) Creating a new template with
    /// the same parameters will overwrite the old one and return the same ID,
    /// (3) After you query a template with its ID, you can verify its
    /// integrity by applying the hash and comparing the result with the ID.
    /// @param airnode Airnode address
    /// @param endpointId Endpoint ID (allowed to be `bytes32(0)`)
    /// @param parameters Static request parameters (i.e., parameters that will
    /// not change between requests, unlike the dynamic parameters determined
    /// at request-time)
    /// @return templateId Request template ID
    function createTemplate(address airnode, bytes32 endpointId, bytes calldata parameters)
        external
        override
        returns (bytes32 templateId)
    {
        require(airnode != address(0), "Airnode address zero");
        templateId = keccak256(abi.encodePacked(airnode, endpointId, parameters));
        templates[templateId] = Template({airnode: airnode, endpointId: endpointId, parameters: parameters});
        emit CreatedTemplate(templateId, airnode, endpointId, parameters);
    }

    /// @notice A convenience method to retrieve multiple templates with a
    /// single call
    /// @dev Does not revert if the templates being indexed do not exist
    /// @param templateIds Request template IDs
    /// @return airnodes Array of Airnode addresses
    /// @return endpointIds Array of endpoint IDs
    /// @return parameters Array of request parameters
    function getTemplates(bytes32[] calldata templateIds)
        external
        view
        override
        returns (address[] memory airnodes, bytes32[] memory endpointIds, bytes[] memory parameters)
    {
        airnodes = new address[](templateIds.length);
        endpointIds = new bytes32[](templateIds.length);
        parameters = new bytes[](templateIds.length);
        for (uint256 ind = 0; ind < templateIds.length; ind++) {
            Template storage template = templates[templateIds[ind]];
            airnodes[ind] = template.airnode;
            endpointIds[ind] = template.endpointId;
            parameters[ind] = template.parameters;
        }
    }
}

interface IWithdrawalUtilsV0 {
    event RequestedWithdrawal(
        address indexed airnode, address indexed sponsor, bytes32 indexed withdrawalRequestId, address sponsorWallet
    );

    event FulfilledWithdrawal(
        address indexed airnode,
        address indexed sponsor,
        bytes32 indexed withdrawalRequestId,
        address sponsorWallet,
        uint256 amount
    );

    function requestWithdrawal(address airnode, address sponsorWallet) external;

    function fulfillWithdrawal(bytes32 withdrawalRequestId, address airnode, address sponsor) external payable;

    function sponsorToWithdrawalRequestCount(address sponsor) external view returns (uint256 withdrawalRequestCount);
}

/// @title Contract that implements logic for withdrawals from sponsor wallets
contract WithdrawalUtilsV0 is IWithdrawalUtilsV0 {
    /// @notice Called to get the withdrawal request count of the sponsor
    /// @dev Can be used to calculate the ID of the next withdrawal request the
    /// sponsor will make
    mapping(address => uint256) public override sponsorToWithdrawalRequestCount;

    /// @dev Hash of expected fulfillment parameters are kept to verify that
    /// the fulfillment will be done with the correct parameters
    mapping(bytes32 => bytes32) private withdrawalRequestIdToParameters;

    /// @notice Called by a sponsor to create a request for the Airnode to send
    /// the funds kept in the respective sponsor wallet to the sponsor
    /// @dev We do not need to use the withdrawal request parameters in the
    /// request ID hash to validate them at the node-side because all of the
    /// parameters are used during fulfillment and will get validated on-chain.
    /// The first withdrawal request a sponsor will make will cost slightly
    /// higher gas than the rest due to how the request counter is implemented.
    /// @param airnode Airnode address
    /// @param sponsorWallet Sponsor wallet that the withdrawal is requested
    /// from
    function requestWithdrawal(address airnode, address sponsorWallet) external override {
        bytes32 withdrawalRequestId = keccak256(
            abi.encodePacked(block.chainid, address(this), msg.sender, ++sponsorToWithdrawalRequestCount[msg.sender])
        );
        withdrawalRequestIdToParameters[withdrawalRequestId] =
            keccak256(abi.encodePacked(airnode, msg.sender, sponsorWallet));
        emit RequestedWithdrawal(airnode, msg.sender, withdrawalRequestId, sponsorWallet);
    }

    /// @notice Called by the Airnode using the sponsor wallet to fulfill the
    /// withdrawal request made by the sponsor
    /// @dev The Airnode sends the funds to the sponsor through this method
    /// to emit an event that indicates that the withdrawal request has been
    /// fulfilled
    /// @param withdrawalRequestId Withdrawal request ID
    /// @param airnode Airnode address
    /// @param sponsor Sponsor address
    function fulfillWithdrawal(bytes32 withdrawalRequestId, address airnode, address sponsor)
        external
        payable
        override
    {
        require(
            withdrawalRequestIdToParameters[withdrawalRequestId]
                == keccak256(abi.encodePacked(airnode, sponsor, msg.sender)),
            "Invalid withdrawal fulfillment"
        );
        delete withdrawalRequestIdToParameters[withdrawalRequestId];
        emit FulfilledWithdrawal(airnode, sponsor, withdrawalRequestId, msg.sender, msg.value);
        (bool success,) = sponsor.call{value: msg.value}(""); // solhint-disable-line avoid-low-level-calls
        require(success, "Transfer failed");
    }
}

interface IAirnodeRrpV0 is IAuthorizationUtilsV0, ITemplateUtilsV0, IWithdrawalUtilsV0 {
    event SetSponsorshipStatus(address indexed sponsor, address indexed requester, bool sponsorshipStatus);

    event MadeTemplateRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        uint256 requesterRequestCount,
        uint256 chainId,
        address requester,
        bytes32 templateId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes parameters
    );

    event MadeFullRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        uint256 requesterRequestCount,
        uint256 chainId,
        address requester,
        bytes32 endpointId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes parameters
    );

    event FulfilledRequest(address indexed airnode, bytes32 indexed requestId, bytes data);

    event FailedRequest(address indexed airnode, bytes32 indexed requestId, string errorMessage);

    function setSponsorshipStatus(address requester, bool sponsorshipStatus) external;

    function makeTemplateRequest(
        bytes32 templateId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata parameters
    ) external returns (bytes32 requestId);

    function makeFullRequest(
        address airnode,
        bytes32 endpointId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata parameters
    ) external returns (bytes32 requestId);

    function fulfill(
        bytes32 requestId,
        address airnode,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata data,
        bytes calldata signature
    ) external returns (bool callSuccess, bytes memory callData);

    function fail(
        bytes32 requestId,
        address airnode,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        string calldata errorMessage
    ) external;

    function sponsorToRequesterToSponsorshipStatus(address sponsor, address requester)
        external
        view
        returns (bool sponsorshipStatus);

    function requesterToRequestCountPlusOne(address requester) external view returns (uint256 requestCountPlusOne);

    function requestIsAwaitingFulfillment(bytes32 requestId) external view returns (bool isAwaitingFulfillment);
}

/// @title Contract that implements the Airnode request–response protocol (RRP)
contract AirnodeRrpV0 is AuthorizationUtilsV0, TemplateUtilsV0, WithdrawalUtilsV0, IAirnodeRrpV0 {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /// @notice Called to get the sponsorship status for a sponsor–requester
    /// pair
    mapping(address => mapping(address => bool)) public override sponsorToRequesterToSponsorshipStatus;

    /// @notice Called to get the request count of the requester plus one
    /// @dev Can be used to calculate the ID of the next request the requester
    /// will make
    mapping(address => uint256) public override requesterToRequestCountPlusOne;

    /// @dev Hash of expected fulfillment parameters are kept to verify that
    /// the fulfillment will be done with the correct parameters. This value is
    /// also used to check if the fulfillment for the particular request is
    /// expected, i.e., if there are recorded fulfillment parameters.
    mapping(bytes32 => bytes32) private requestIdToFulfillmentParameters;

    /// @notice Called by the sponsor to set the sponsorship status of a
    /// requester, i.e., allow or disallow a requester to make requests that
    /// will be fulfilled by the sponsor wallet
    /// @dev This is not Airnode-specific, i.e., the sponsor allows the
    /// requester's requests to be fulfilled through its sponsor wallets across
    /// all Airnodes
    /// @param requester Requester address
    /// @param sponsorshipStatus Sponsorship status
    function setSponsorshipStatus(address requester, bool sponsorshipStatus) external override {
        // Initialize the requester request count for consistent request gas
        // cost
        if (requesterToRequestCountPlusOne[requester] == 0) {
            requesterToRequestCountPlusOne[requester] = 1;
        }
        sponsorToRequesterToSponsorshipStatus[msg.sender][requester] = sponsorshipStatus;
        emit SetSponsorshipStatus(msg.sender, requester, sponsorshipStatus);
    }

    /// @notice Called by the requester to make a request that refers to a
    /// template for the Airnode address, endpoint ID and parameters
    /// @dev `fulfillAddress` is not allowed to be the address of this
    /// contract. This is not actually needed to protect users that use the
    /// protocol as intended, but it is done for good measure.
    /// @param templateId Template ID
    /// @param sponsor Sponsor address
    /// @param sponsorWallet Sponsor wallet that is requested to fulfill the
    /// request
    /// @param fulfillAddress Address that will be called to fulfill
    /// @param fulfillFunctionId Signature of the function that will be called
    /// to fulfill
    /// @param parameters Parameters provided by the requester in addition to
    /// the parameters in the template
    /// @return requestId Request ID
    function makeTemplateRequest(
        bytes32 templateId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata parameters
    ) external override returns (bytes32 requestId) {
        address airnode = templates[templateId].airnode;
        // If the Airnode address of the template is zero the template does not
        // exist because template creation does not allow zero Airnode address
        require(airnode != address(0), "Template does not exist");
        require(fulfillAddress != address(this), "Fulfill address AirnodeRrp");
        require(sponsorToRequesterToSponsorshipStatus[sponsor][msg.sender], "Requester not sponsored");
        uint256 requesterRequestCount = requesterToRequestCountPlusOne[msg.sender];
        requestId = keccak256(
            abi.encodePacked(
                block.chainid,
                address(this),
                msg.sender,
                requesterRequestCount,
                templateId,
                sponsor,
                sponsorWallet,
                fulfillAddress,
                fulfillFunctionId,
                parameters
            )
        );
        requestIdToFulfillmentParameters[requestId] =
            keccak256(abi.encodePacked(airnode, sponsorWallet, fulfillAddress, fulfillFunctionId));
        requesterToRequestCountPlusOne[msg.sender]++;
        emit MadeTemplateRequest(
            airnode,
            requestId,
            requesterRequestCount,
            block.chainid,
            msg.sender,
            templateId,
            sponsor,
            sponsorWallet,
            fulfillAddress,
            fulfillFunctionId,
            parameters
        );
    }

    /// @notice Called by the requester to make a full request, which provides
    /// all of its parameters as arguments and does not refer to a template
    /// @dev `fulfillAddress` is not allowed to be the address of this
    /// contract. This is not actually needed to protect users that use the
    /// protocol as intended, but it is done for good measure.
    /// @param airnode Airnode address
    /// @param endpointId Endpoint ID (allowed to be `bytes32(0)`)
    /// @param sponsor Sponsor address
    /// @param sponsorWallet Sponsor wallet that is requested to fulfill
    /// the request
    /// @param fulfillAddress Address that will be called to fulfill
    /// @param fulfillFunctionId Signature of the function that will be called
    /// to fulfill
    /// @param parameters All request parameters
    /// @return requestId Request ID
    function makeFullRequest(
        address airnode,
        bytes32 endpointId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata parameters
    ) external override returns (bytes32 requestId) {
        require(airnode != address(0), "Airnode address zero");
        require(fulfillAddress != address(this), "Fulfill address AirnodeRrp");
        require(sponsorToRequesterToSponsorshipStatus[sponsor][msg.sender], "Requester not sponsored");
        uint256 requesterRequestCount = requesterToRequestCountPlusOne[msg.sender];
        requestId = keccak256(
            abi.encodePacked(
                block.chainid,
                address(this),
                msg.sender,
                requesterRequestCount,
                airnode,
                endpointId,
                sponsor,
                sponsorWallet,
                fulfillAddress,
                fulfillFunctionId,
                parameters
            )
        );
        requestIdToFulfillmentParameters[requestId] =
            keccak256(abi.encodePacked(airnode, sponsorWallet, fulfillAddress, fulfillFunctionId));
        requesterToRequestCountPlusOne[msg.sender]++;
        emit MadeFullRequest(
            airnode,
            requestId,
            requesterRequestCount,
            block.chainid,
            msg.sender,
            endpointId,
            sponsor,
            sponsorWallet,
            fulfillAddress,
            fulfillFunctionId,
            parameters
        );
    }

    /// @notice Called by Airnode to fulfill the request (template or full)
    /// @dev The data is ABI-encoded as a `bytes` type, with its format
    /// depending on the request specifications.
    /// This will not revert depending on the external call. However, it will
    /// return `false` if the external call reverts or if there is no function
    /// with a matching signature at `fulfillAddress`. On the other hand, it
    /// will return `true` if the external call returns successfully or if
    /// there is no contract deployed at `fulfillAddress`.
    /// If `callSuccess` is `false`, `callData` can be decoded to retrieve the
    /// revert string.
    /// This function emits its event after an untrusted low-level call,
    /// meaning that the order of these events within the transaction should
    /// not be taken seriously, yet the content will be sound.
    /// @param requestId Request ID
    /// @param airnode Airnode address
    /// @param data Fulfillment data
    /// @param fulfillAddress Address that will be called to fulfill
    /// @param fulfillFunctionId Signature of the function that will be called
    /// to fulfill
    /// @return callSuccess If the fulfillment call succeeded
    /// @return callData Data returned by the fulfillment call (if there is
    /// any)
    function fulfill(
        bytes32 requestId,
        address airnode,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata data,
        bytes calldata signature
    ) external override returns (bool callSuccess, bytes memory callData) {
        require(
            keccak256(abi.encodePacked(airnode, msg.sender, fulfillAddress, fulfillFunctionId))
                == requestIdToFulfillmentParameters[requestId],
            "Invalid request fulfillment"
        );
        require(
            (keccak256(abi.encodePacked(requestId, data)).toEthSignedMessageHash()).recover(signature) == airnode,
            "Invalid signature"
        );
        delete requestIdToFulfillmentParameters[requestId];
        (callSuccess, callData) = fulfillAddress.call( // solhint-disable-line avoid-low-level-calls
        abi.encodeWithSelector(fulfillFunctionId, requestId, data));
        if (callSuccess) {
            emit FulfilledRequest(airnode, requestId, data);
        } else {
            // We do not bubble up the revert string from `callData`
            emit FailedRequest(airnode, requestId, "Fulfillment failed unexpectedly");
        }
    }

    /// @notice Called by Airnode if the request cannot be fulfilled
    /// @dev Airnode should fall back to this if a request cannot be fulfilled
    /// because static call to `fulfill()` returns `false` for `callSuccess`
    /// @param requestId Request ID
    /// @param airnode Airnode address
    /// @param fulfillAddress Address that will be called to fulfill
    /// @param fulfillFunctionId Signature of the function that will be called
    /// to fulfill
    /// @param errorMessage A message that explains why the request has failed
    function fail(
        bytes32 requestId,
        address airnode,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        string calldata errorMessage
    ) external override {
        require(
            keccak256(abi.encodePacked(airnode, msg.sender, fulfillAddress, fulfillFunctionId))
                == requestIdToFulfillmentParameters[requestId],
            "Invalid request fulfillment"
        );
        delete requestIdToFulfillmentParameters[requestId];
        emit FailedRequest(airnode, requestId, errorMessage);
    }

    /// @notice Called to check if the request with the ID is made but not
    /// fulfilled/failed yet
    /// @dev If a requester has made a request, received a request ID but did
    /// not hear back, it can call this method to check if the Airnode has
    /// called back `fail()` instead.
    /// @param requestId Request ID
    /// @return isAwaitingFulfillment If the request is awaiting fulfillment
    /// (i.e., `true` if `fulfill()` or `fail()` is not called back yet,
    /// `false` otherwise)
    function requestIsAwaitingFulfillment(bytes32 requestId)
        external
        view
        override
        returns (bool isAwaitingFulfillment)
    {
        isAwaitingFulfillment = requestIdToFulfillmentParameters[requestId] != bytes32(0);
    }
}
