const std = @import("std");
const primitives = @import("../primitives/types.zig");
const preset = @import("../presets/preset.zig");
const constants = @import("../primitives/constants.zig");
const phase0 = @import("../consensus/phase0/types.zig");
const altair = @import("../consensus/altair/types.zig");
const bellatrix = @import("../consensus/bellatrix/types.zig");
const capella = @import("../consensus/capella/types.zig");
const deneb = @import("../consensus/deneb/types.zig");
const electra = @import("../consensus/electra/types.zig");
const configs = @import("../configs/config.zig");

pub const NonExistType = struct {};

pub const Fork = struct {
    previous_version: primitives.Version,
    current_version: primitives.Version,
    epoch: primitives.Epoch,
};

pub const ForkData = struct {
    current_version: primitives.Version,
    genesis_validators_root: primitives.Root,
};

pub const Checkpoint = struct {
    epoch: primitives.Epoch,
    root: primitives.Root,
};

pub const Validator = struct {
    pubkey: primitives.BLSPubkey,
    withdrawal_credentials: primitives.Bytes32,
    effective_balance: primitives.Gwei,
    slashed: bool,
    activation_eligibility_epoch: primitives.Epoch,
    activation_epoch: primitives.Epoch,
    exit_epoch: primitives.Epoch,
    withdrawable_epoch: primitives.Epoch,

    /// getValidatorFromDeposit creates a new validator from a deposit.
    /// @param pubkey The public key of the validator.
    /// @param withdrawal_credentials The withdrawal credentials of the validator.
    /// @param amount The amount of the deposit.
    /// @return The validator.
    /// Spec pseudocode definition:
    /// def get_validator_from_deposit(pubkey: BLSPubkey, withdrawal_credentials: Bytes32, amount: uint64) -> Validator:
    ///     effective_balance = min(amount - amount % EFFECTIVE_BALANCE_INCREMENT, MAX_EFFECTIVE_BALANCE)
    ///
    ///     return Validator(
    ///                      pubkey=pubkey,
    ///                      withdrawal_credentials=withdrawal_credentials,
    ///                      activation_eligibility_epoch=FAR_FUTURE_EPOCH,
    ///                      activation_epoch=FAR_FUTURE_EPOCH,
    ///                      exit_epoch=FAR_FUTURE_EPOCH,
    ///                      withdrawable_epoch=FAR_FUTURE_EPOCH,
    ///                      effective_balance=effective_balance,
    ///     )
    pub fn getValidatorFromDeposit(pubkey: *const primitives.BLSPubkey, withdrawal_credentials: *const primitives.Bytes32, amount: u64) Validator {
        const effective_balance = @min(amount - @mod(amount, preset.ActivePreset.get().EFFECTIVE_BALANCE_INCREMENT), preset.ActivePreset.get().MAX_EFFECTIVE_BALANCE);

        return Validator{
            .pubkey = pubkey.*,
            .withdrawal_credentials = withdrawal_credentials.*,
            .activation_eligibility_epoch = constants.FAR_FUTURE_EPOCH,
            .activation_epoch = constants.FAR_FUTURE_EPOCH,
            .exit_epoch = constants.FAR_FUTURE_EPOCH,
            .withdrawable_epoch = constants.FAR_FUTURE_EPOCH,
            .effective_balance = effective_balance,
            .slashed = false,
        };
    }
};

pub const AttestationData = struct {
    slot: primitives.Slot,
    index: primitives.CommitteeIndex,
    // LMD GHOST vote
    beacon_block_root: primitives.Root,
    // FFG vote
    source: Checkpoint,
    target: Checkpoint,
};

pub const IndexedAttestation = struct {
    // # [Modified in Electra:EIP7549] size: MAX_VALIDATORS_PER_COMMITTEE * MAX_COMMITTEES_PER_SLOT
    attesting_indices: []primitives.ValidatorIndex,
    data: AttestationData,
    signature: primitives.BLSSignature,

    pub fn deinit(self: *const IndexedAttestation, allocator: std.mem.Allocator) void {
        allocator.free(self.attesting_indices);
    }
};

pub const PendingAttestation = struct {
    aggregation_bits: []bool,
    data: AttestationData,
    inclusion_delay: primitives.Slot,
    proposer_index: primitives.ValidatorIndex,
};

pub const Eth1Data = struct {
    deposit_root: primitives.Root,
    deposit_count: u64,
    block_hash: primitives.Hash32,
};

pub const HistoricalBatch = struct {
    block_roots: []primitives.Root,
    state_roots: []primitives.Root,
};

pub const DepositMessage = struct {
    pubkey: primitives.BLSPubkey,
    withdrawal_credentials: primitives.Bytes32,
    amount: primitives.Gwei,
};

pub const DepositData = struct {
    pubkey: primitives.BLSPubkey,
    withdrawal_credentials: primitives.Bytes32,
    amount: primitives.Gwei,
    signature: primitives.BLSSignature,
};

pub const BeaconBlockHeader = struct {
    slot: primitives.Slot,
    proposer_index: primitives.ValidatorIndex,
    parent_root: primitives.Root,
    state_root: primitives.Root,
    body_root: primitives.Root,
};

pub const SigningData = struct {
    object_root: primitives.Root,
    domain: primitives.Domain,
};

pub const AttesterSlashing = struct {
    attestation_1: IndexedAttestation, // # [Modified in Electra:EIP7549]
    attestation_2: IndexedAttestation, // # [Modified in Electra:EIP7549]
};

pub const Attestation = union(primitives.ForkType) {
    phase0: phase0.Attestation,
    altair: phase0.Attestation,
    bellatrix: phase0.Attestation,
    capella: phase0.Attestation,
    deneb: phase0.Attestation,
    electra: electra.Attestation,

    pub fn signature(self: *const Attestation) primitives.BLSSignature {
        return switch (self.*) {
            inline else => |attestation| attestation.signature,
        };
    }

    pub fn data(self: *const Attestation) AttestationData {
        return switch (self.*) {
            inline else => |attestation| attestation.data,
        };
    }

    pub fn aggregationBits(self: *const Attestation) []bool {
        return switch (self.*) {
            inline else => |attestation| attestation.aggregation_bits,
        };
    }
};

pub const Deposit = struct {
    proof: [constants.DEPOSIT_CONTRACT_TREE_DEPTH + 1]primitives.Bytes32,
    data: DepositData,
};

pub const VoluntaryExit = struct {
    epoch: primitives.Epoch,
    validator_index: primitives.ValidatorIndex,
};

pub const SignedVoluntaryExit = struct {
    message: VoluntaryExit,
    signature: primitives.BLSSignature,
};

pub const SignedBeaconBlockHeader = struct {
    message: BeaconBlockHeader,
    signature: primitives.BLSSignature,
};

pub const ProposerSlashing = struct {
    signed_header_1: SignedBeaconBlockHeader,
    signed_header_2: SignedBeaconBlockHeader,
};

pub const Eth1Block = struct {
    timestamp: u64,
    deposit_root: primitives.Root,
    deposit_count: u64,
};

pub const AggregateAndProof = struct {
    aggregator_index: primitives.ValidatorIndex,
    aggregate: Attestation,
    selection_proof: primitives.BLSSignature,
};

pub const SyncAggregate = union(primitives.ForkType) {
    phase0: NonExistType,
    altair: altair.SyncAggregate,
    bellatrix: altair.SyncAggregate,
    capella: altair.SyncAggregate,
    deneb: altair.SyncAggregate,
    electra: altair.SyncAggregate,
};

pub const SyncCommittee = union(primitives.ForkType) {
    phase0: NonExistType,
    altair: altair.SyncCommittee,
    bellatrix: altair.SyncCommittee,
    capella: altair.SyncCommittee,
    deneb: altair.SyncCommittee,
    electra: altair.SyncCommittee,

    pub fn deinit(self: *const SyncCommittee, allocator: std.mem.Allocator) void {
        switch (self.*) {
            .altair, .bellatrix, .capella, .deneb, .electra => |committee| allocator.free(committee.pubkeys),
            else => {},
        }
    }
};

pub const SyncCommitteeMessage = union(primitives.ForkType) {
    phase0: NonExistType,
    altair: altair.SyncCommitteeMessage,
    bellatrix: altair.SyncCommitteeMessage,
    capella: altair.SyncCommitteeMessage,
    deneb: altair.SyncCommitteeMessage,
    electra: altair.SyncCommitteeMessage,
};

pub const SyncCommitteeContribution = union(primitives.ForkType) {
    phase0: NonExistType,
    altair: altair.SyncCommitteeContribution,
    bellatrix: altair.SyncCommitteeContribution,
    capella: altair.SyncCommitteeContribution,
    deneb: altair.SyncCommitteeContribution,
    electra: altair.SyncCommitteeContribution,
};

pub const ContributionAndProof = union(primitives.ForkType) {
    phase0: NonExistType,
    altair: altair.ContributionAndProof,
    bellatrix: altair.ContributionAndProof,
    capella: altair.ContributionAndProof,
    deneb: altair.ContributionAndProof,
    electra: altair.ContributionAndProof,
};

pub const SignedContributionAndProof = union(primitives.ForkType) {
    phase0: NonExistType,
    altair: altair.SignedContributionAndProof,
    bellatrix: altair.SignedContributionAndProof,
    capella: altair.SignedContributionAndProof,
    deneb: altair.SignedContributionAndProof,
    electra: altair.SignedContributionAndProof,
};

pub const BeaconBlock = struct {
    slot: primitives.Slot,
    proposer_index: primitives.ValidatorIndex,
    parent_root: primitives.Root,
    state_root: primitives.Root,
    body: BeaconBlockBody,
};

pub const BeaconBlockBody = union(primitives.ForkType) {
    phase0: phase0.BeaconBlockBody,
    altair: altair.BeaconBlockBody,
    bellatrix: bellatrix.BeaconBlockBody,
    capella: capella.BeaconBlockBody,
    deneb: deneb.BeaconBlockBody,
    electra: deneb.BeaconBlockBody,
};

pub const SignedBeaconBlock = struct {
    message: BeaconBlock,
    signature: primitives.BLSSignature,
};

pub const SyncAggregatorSelectionData = struct {
    slot: primitives.Slot,
    subcommittee_index: u64,
};

pub const ExecutionPayloadHeader = union(primitives.ForkType) {
    phase0: NonExistType,
    altair: NonExistType,
    bellatrix: bellatrix.ExecutionPayloadHeader,
    capella: capella.ExecutionPayloadHeader,
    deneb: deneb.ExecutionPayloadHeader,
    electra: electra.ExecutionPayloadHeader,

    pub fn default(fork_type: primitives.ForkType) ExecutionPayloadHeader {
        return switch (fork_type) {
            primitives.ForkType.phase0 => .{ .phase0 = NonExistType{} },
            primitives.ForkType.altair => .{ .altair = NonExistType{} },
            primitives.ForkType.bellatrix => .{ .bellatrix = bellatrix.ExecutionPayloadHeader{
                .parent_hash = undefined,
                .fee_recipient = undefined,
                .state_root = undefined,
                .receipts_root = undefined,
                .logs_bloom = undefined,
                .prev_randao = undefined,
                .block_number = 0,
                .gas_used = 0,
                .gas_limit = 0,
                .timestamp = 0,
                .extra_data = undefined,
                .base_fee_per_gas = 0,
                .block_hash = undefined,
                .transactions_root = undefined,
            } },
            primitives.ForkType.capella => .{ .capella = capella.ExecutionPayloadHeader{
                .parent_hash = undefined,
                .fee_recipient = undefined,
                .state_root = undefined,
                .receipts_root = undefined,
                .logs_bloom = undefined,
                .prev_randao = undefined,
                .block_number = 0,
                .gas_used = 0,
                .gas_limit = 0,
                .timestamp = 0,
                .extra_data = undefined,
                .base_fee_per_gas = 0,
                .block_hash = undefined,
                .transactions_root = undefined,
                .withdrawals_root = undefined,
            } },
            primitives.ForkType.deneb => .{ .deneb = deneb.ExecutionPayloadHeader{
                .parent_hash = undefined,
                .fee_recipient = undefined,
                .state_root = undefined,
                .receipts_root = undefined,
                .logs_bloom = undefined,
                .prev_randao = undefined,
                .block_number = 0,
                .gas_used = 0,
                .gas_limit = 0,
                .timestamp = 0,
                .extra_data = undefined,
                .base_fee_per_gas = 0,
                .block_hash = undefined,
                .transactions_root = undefined,
                .withdrawals_root = undefined,
                .blob_gas_used = 0,
                .excess_blob_gas = 0,
            } },
            primitives.ForkType.electra => .{ .electra = electra.ExecutionPayloadHeader{
                .parent_hash = undefined,
                .fee_recipient = undefined,
                .state_root = undefined,
                .receipts_root = undefined,
                .logs_bloom = undefined,
                .prev_randao = undefined,
                .block_number = 0,
                .gas_used = 0,
                .gas_limit = 0,
                .timestamp = 0,
                .extra_data = undefined,
                .base_fee_per_gas = 0,
                .block_hash = undefined,
                .transactions_root = undefined,
                .withdrawals_root = undefined,
                .blob_gas_used = 0,
                .excess_blob_gas = 0,
                .deposit_requests_root = undefined,
                .withdrawal_requests_root = undefined,
                .consolidation_requests_root = undefined,
            } },
        };
    }
};

pub const ExecutionPayload = union(primitives.ForkType) {
    phase0: NonExistType,
    altair: NonExistType,
    bellatrix: bellatrix.ExecutionPayload,
    capella: capella.ExecutionPayload,
    deneb: deneb.ExecutionPayload,
    electra: electra.ExecutionPayload,
};

pub const LightClientHeader = union(primitives.ForkType) {
    phase0: NonExistType,
    altair: altair.LightClientHeader,
    bellatrix: altair.LightClientHeader,
    capella: capella.LightClientHeader,
    deneb: capella.LightClientHeader,
    electra: capella.LightClientHeader,
};

pub const LightClientOptimisticUpdate = union(primitives.ForkType) {
    phase0: NonExistType,
    altair: altair.LightClientOptimisticUpdate,
    bellatrix: altair.LightClientOptimisticUpdate,
    capella: altair.LightClientOptimisticUpdate,
    deneb: altair.LightClientOptimisticUpdate,
    electra: altair.LightClientOptimisticUpdate,
};

pub const LightClientFinalityUpdate = union(primitives.ForkType) {
    phase0: NonExistType,
    altair: altair.LightClientFinalityUpdate,
    bellatrix: altair.LightClientFinalityUpdate,
    capella: altair.LightClientFinalityUpdate,
    deneb: altair.LightClientFinalityUpdate,
    electra: altair.LightClientFinalityUpdate,
};

pub const LightClientUpdate = union(primitives.ForkType) {
    phase0: NonExistType,
    altair: altair.LightClientUpdate,
    bellatrix: altair.LightClientUpdate,
    capella: altair.LightClientUpdate,
    deneb: altair.LightClientUpdate,
    electra: altair.LightClientUpdate,
};

pub const LightClientBootstrap = union(primitives.ForkType) {
    phase0: NonExistType,
    altair: altair.LightClientBootstrap,
    bellatrix: altair.LightClientBootstrap,
    capella: altair.LightClientBootstrap,
    deneb: altair.LightClientBootstrap,
    electra: altair.LightClientBootstrap,
};

pub const PowBlock = union(primitives.ForkType) {
    phase0: NonExistType,
    altair: NonExistType,
    bellatrix: bellatrix.PowBlock,
    capella: bellatrix.PowBlock,
    deneb: bellatrix.PowBlock,
    electra: bellatrix.PowBlock,
};

pub const Withdrawal = union(primitives.ForkType) {
    phase0: NonExistType,
    altair: NonExistType,
    bellatrix: NonExistType,
    capella: capella.Withdrawal,
    deneb: capella.Withdrawal,
    electra: capella.Withdrawal,
};

pub const BLSToExecutionChange = union(primitives.ForkType) {
    phase0: NonExistType,
    altair: NonExistType,
    bellatrix: NonExistType,
    capella: capella.BLSToExecutionChange,
    deneb: capella.BLSToExecutionChange,
    electra: capella.BLSToExecutionChange,
};

pub const SignedBLSToExecutionChange = union(primitives.ForkType) {
    phase0: NonExistType,
    altair: NonExistType,
    bellatrix: NonExistType,
    capella: capella.SignedBLSToExecutionChange,
    deneb: capella.SignedBLSToExecutionChange,
    electra: capella.SignedBLSToExecutionChange,
};

pub const HistoricalSummary = union(primitives.ForkType) {
    phase0: NonExistType,
    altair: NonExistType,
    bellatrix: NonExistType,
    capella: capella.HistoricalSummary,
    deneb: capella.HistoricalSummary,
    electra: capella.HistoricalSummary,
};

pub const BlobSidecar = union(primitives.ForkType) {
    phase0: NonExistType,
    altair: NonExistType,
    bellatrix: NonExistType,
    capella: NonExistType,
    deneb: deneb.BlobSidecar,
    electra: deneb.BlobSidecar,
};

pub const BlobIdentifier = union(primitives.ForkType) {
    phase0: NonExistType,
    altair: NonExistType,
    bellatrix: NonExistType,
    capella: NonExistType,
    deneb: deneb.BlobIdentifier,
    electra: deneb.BlobIdentifier,
};

pub const DepositRequest = union(primitives.ForkType) {
    phase0: NonExistType,
    altair: NonExistType,
    bellatrix: NonExistType,
    capella: NonExistType,
    deneb: NonExistType,
    electra: electra.DepositRequest,
};

pub const PendingBalanceDeposit = union(primitives.ForkType) {
    phase0: NonExistType,
    altair: NonExistType,
    bellatrix: NonExistType,
    capella: NonExistType,
    deneb: NonExistType,
    electra: electra.PendingBalanceDeposit,
};

pub const PendingPartialWithdrawal = union(primitives.ForkType) {
    phase0: NonExistType,
    altair: NonExistType,
    bellatrix: NonExistType,
    capella: NonExistType,
    deneb: NonExistType,
    electra: electra.PendingPartialWithdrawal,

    pub fn index(self: *const PendingPartialWithdrawal) primitives.ValidatorIndex {
        return switch (self.*) {
            .phase0, .altair, .bellatrix, .capella, .deneb => @panic("index is not supported for phase0, altair, bellatrix, capella, deneb"),
            inline else => |withdrawal| withdrawal.index,
        };
    }

    pub fn amount(self: *const PendingPartialWithdrawal) primitives.Gwei {
        return switch (self.*) {
            .phase0, .altair, .bellatrix, .capella, .deneb => @panic("amount is not supported for phase0, altair, bellatrix, capella, deneb"),
            inline else => |withdrawal| withdrawal.amount,
        };
    }
};

pub const WithdrawalRequest = union(primitives.ForkType) {
    phase0: NonExistType,
    altair: NonExistType,
    bellatrix: NonExistType,
    capella: NonExistType,
    deneb: NonExistType,
    electra: electra.WithdrawalRequest,
};

pub const ConsolidationRequest = union(primitives.ForkType) {
    phase0: NonExistType,
    altair: NonExistType,
    bellatrix: NonExistType,
    capella: NonExistType,
    deneb: NonExistType,
    electra: electra.ConsolidationRequest,
};

pub const PendingConsolidation = union(primitives.ForkType) {
    phase0: NonExistType,
    altair: NonExistType,
    bellatrix: NonExistType,
    capella: NonExistType,
    deneb: NonExistType,
    electra: electra.PendingConsolidation,
};

pub const BeaconState = union(primitives.ForkType) {
    phase0: phase0.BeaconState,
    altair: altair.BeaconState,
    bellatrix: bellatrix.BeaconState,
    capella: capella.BeaconState,
    deneb: capella.BeaconState,
    electra: electra.BeaconState,

    pub fn setEth1DepositIndex(self: *BeaconState, index: u64) void {
        switch (self.*) {
            inline else => |*state| state.eth1_deposit_index = index,
        }
    }

    pub fn setLatestExecutionPayloadHeader(self: *BeaconState, header: *const ExecutionPayloadHeader) void {
        const supported_forks = [_]primitives.ForkType{
            .bellatrix,
            .capella,
            .deneb,
            .electra,
        };

        inline for (supported_forks) |f| {
            if (std.meta.activeTag(self.*) == f) {
                @field(self, @tagName(f)).latest_execution_payload_header = header.*;
                return;
            }
        }
    }

    pub fn setCurrentSyncCommittee(self: *BeaconState, sync_committee: *const SyncCommittee) void {
        const supported_forks = [_]primitives.ForkType{
            .altair,
            .bellatrix,
            .capella,
            .deneb,
            .electra,
        };

        inline for (supported_forks) |f| {
            if (std.meta.activeTag(self.*) == f) {
                @field(self, @tagName(f)).current_sync_committee = sync_committee.*;
                return;
            }
        }
    }

    /// setNextSyncCommittee sets the next sync committee.
    pub fn setNextSyncCommittee(self: *BeaconState, sync_committee: *const SyncCommittee) void {
        const supported_forks = [_]primitives.ForkType{
            .altair,
            .bellatrix,
            .capella,
            .deneb,
            .electra,
        };

        inline for (supported_forks) |f| {
            if (std.meta.activeTag(self.*) == f) {
                @field(self, @tagName(f)).next_sync_committee = sync_committee.*;
                return;
            }
        }
    }

    /// eth1Data returns the eth1 data of the given state.
    pub fn eth1Data(self: *BeaconState) *Eth1Data {
        return switch (self.*) {
            inline else => |*state| &state.eth1_data,
        };
    }

    /// genesisTime returns the genesis time of the given state.
    pub fn genesisTime(self: *const BeaconState) u64 {
        return switch (self.*) {
            inline else => |state| state.genesis_time,
        };
    }

    /// slashings returns the slashings of the given state.
    pub fn slashings(self: *const BeaconState) []primitives.Gwei {
        return switch (self.*) {
            inline else => |state| state.slashings,
        };
    }

    /// balances returns the balances of the given state.
    pub fn balances(self: *const BeaconState) []primitives.Gwei {
        return switch (self.*) {
            inline else => |state| state.balances,
        };
    }

    /// genesisValidatorsRoot returns the genesis validators root of the given state.
    pub fn genesisValidatorsRoot(self: *const BeaconState) primitives.Root {
        return switch (self.*) {
            inline else => |state| state.genesis_validators_root,
        };
    }

    /// genesisValidatorsRootPtr returns a pointer to the genesis validators root of the given state.
    pub fn genesisValidatorsRootPtr(self: *BeaconState) *primitives.Root {
        return switch (self.*) {
            inline else => |*state| &state.genesis_validators_root,
        };
    }

    /// fork returns the fork of the given state.
    pub fn fork(self: *const BeaconState) Fork {
        return switch (self.*) {
            inline else => |state| state.fork,
        };
    }

    /// randaoMixes returns the randao mixes of the given state.
    /// @return The randao mixes of the state.
    pub fn randaoMixes(self: *const BeaconState) []const primitives.Root {
        return switch (self.*) {
            inline else => |state| state.randao_mixes,
        };
    }

    /// blockRoots returns the block roots of the given state.
    /// @return The block roots of the state.
    pub fn blockRoots(self: *const BeaconState) []const primitives.Root {
        return switch (self.*) {
            inline else => |state| state.block_roots,
        };
    }

    /// slot returns the slot of the given state.
    /// @return The slot of the state.
    pub fn slot(self: *const BeaconState) primitives.Slot {
        return switch (self.*) {
            inline else => |state| state.slot,
        };
    }

    /// validators returns the validators of the given state.
    /// @return The validators of the state.
    pub fn validators(self: *const BeaconState) []Validator {
        return switch (self.*) {
            inline else => |state| state.validators,
        };
    }

    /// finalizedCheckpointEpoch returns the epoch of the finalized checkpoint of the given state.
    pub fn finalizedCheckpointEpoch(self: *const BeaconState) primitives.Epoch {
        return switch (self.*) {
            inline else => |state| state.finalized_checkpoint.epoch,
        };
    }

    /// getIndexForNewValidator returns the index for a new validator.
    ///
    /// Spec pseudocode definition:
    /// def get_index_for_new_validator(state: BeaconState) -> ValidatorIndex:
    ///     return ValidatorIndex(len(state.validators))
    pub fn getIndexForNewValidator(self: *const BeaconState) primitives.ValidatorIndex {
        return @as(primitives.ValidatorIndex, self.validators().len);
    }

    /// previousEpochParticipation returns the previous epoch participation of the given state.
    pub fn previousEpochParticipation(self: *const BeaconState) []u8 {
        return switch (self.*) {
            .phase0 => @panic("previous_epoch_participation is not supported for phase0"),
            inline else => |state| state.previous_epoch_participation,
        };
    }

    /// currentEpochParticipation returns the current epoch participation of the given state.
    pub fn currentEpochParticipation(self: *const BeaconState) []u8 {
        return switch (self.*) {
            .phase0 => @panic("current_epoch_participation is not supported for phase0"),
            inline else => |state| state.current_epoch_participation,
        };
    }

    pub fn currentJustifiedCheckpoint(self: *const BeaconState) Checkpoint {
        return switch (self.*) {
            inline else => |state| state.current_justified_checkpoint,
        };
    }

    pub fn setCurrentJustifiedCheckpoint(self: *BeaconState, checkpoint: *const Checkpoint) void {
        switch (self.*) {
            inline else => |*state| state.current_justified_checkpoint = checkpoint.*,
        }
    }

    pub fn previousJustifiedCheckpoint(self: *const BeaconState) Checkpoint {
        return switch (self.*) {
            inline else => |state| state.previous_justified_checkpoint,
        };
    }

    pub fn setPreviousJustifiedCheckpoint(self: *BeaconState, checkpoint: *const Checkpoint) void {
        switch (self.*) {
            inline else => |*state| state.previous_justified_checkpoint = checkpoint.*,
        }
    }

    pub fn justificationBits(self: *const BeaconState) []bool {
        return switch (self.*) {
            inline else => |state| state.justification_bits,
        };
    }

    pub fn setFinalizedCheckpoint(self: *BeaconState, checkpoint: *const Checkpoint) void {
        switch (self.*) {
            inline else => |*state| state.finalized_checkpoint = checkpoint.*,
        }
    }

    /// inactivityScores returns the inactivity scores of the given state.
    pub fn inactivityScores(self: *const BeaconState) []u64 {
        return switch (self.*) {
            .phase0 => @panic("inactivity_scores is not supported for phase0"),
            inline else => |state| state.inactivity_scores,
        };
    }

    /// pendingBalanceDeposits returns the pending balance deposits of the given state.
    pub fn pendingBalanceDeposit(self: *const BeaconState) []PendingBalanceDeposit {
        return switch (self.*) {
            .phase0, .altair, .bellatrix, .capella, .deneb => @panic("pending_balance_deposits is not supported for phase0, altair, bellatrix, capella, deneb"),
            inline else => |state| state.pending_balance_deposits,
        };
    }

    /// pendingPartialWithdrawals returns the pending partial withdrawals of the given state.
    pub fn pendingPartialWithdrawals(self: *const BeaconState) []PendingPartialWithdrawal {
        return switch (self.*) {
            .phase0, .altair, .bellatrix, .capella, .deneb => @panic("pending_partial_withdrawals is not supported for phase0, altair, bellatrix, capella, deneb"),
            inline else => |state| state.pending_partial_withdrawals,
        };
    }

    /// eth1DepositIndex returns the eth1 deposit index of the given state.
    pub fn eth1DepositIndex(self: *const BeaconState) u64 {
        return switch (self.*) {
            inline else => |state| state.eth1_deposit_index,
        };
    }
};

test "test Attestation" {
    const attestation = Attestation{
        .phase0 = phase0.Attestation{
            .aggregation_bits = &[_]bool{},
            .data = undefined,
            .signature = undefined,
        },
    };

    try std.testing.expectEqual(attestation.phase0.aggregation_bits.len, 0);

    const attestation1 = Attestation{
        .altair = phase0.Attestation{
            .aggregation_bits = &[_]bool{},
            .data = undefined,
            .signature = undefined,
        },
    };

    try std.testing.expectEqual(attestation1.altair.aggregation_bits.len, 0);
}

test "test SyncAggregate" {
    const aggregate = SyncAggregate{
        .phase0 = NonExistType{},
    };

    try std.testing.expectEqual(aggregate.phase0, NonExistType{});

    const aggregate1 = SyncAggregate{
        .altair = altair.SyncAggregate{
            .sync_committee_bits = &[_]bool{},
            .sync_committee_signature = undefined,
        },
    };

    try std.testing.expectEqual(aggregate1.altair.sync_committee_bits.len, 0);
}

test "test BeaconBlock" {
    const block = BeaconBlock{
        .slot = 0,
        .proposer_index = 0,
        .parent_root = undefined,
        .state_root = undefined,
        .body = undefined,
    };

    try std.testing.expectEqual(block.slot, 0);
}

test "test BeaconBlockBody" {
    const body = BeaconBlockBody{
        .phase0 = phase0.BeaconBlockBody{
            .randao_reveal = undefined,
            .eth1_data = undefined,
            .graffiti = undefined,
            .proposer_slashings = undefined,
            .attester_slashings = undefined,
            .attestations = undefined,
            .deposits = undefined,
            .voluntary_exits = undefined,
        },
    };

    try std.testing.expectEqual(body.phase0.randao_reveal.len, 96);

    const body1 = BeaconBlockBody{
        .altair = altair.BeaconBlockBody{
            .randao_reveal = undefined,
            .eth1_data = undefined,
            .graffiti = undefined,
            .proposer_slashings = undefined,
            .attester_slashings = undefined,
            .attestations = undefined,
            .deposits = undefined,
            .voluntary_exits = undefined,
            .sync_aggregate = undefined,
        },
    };

    try std.testing.expectEqual(body1.altair.randao_reveal.len, 96);
}

test "test SignedBeaconBlockHeader" {
    const header = SignedBeaconBlockHeader{
        .message = undefined,
        .signature = undefined,
    };

    try std.testing.expectEqual(header.message, undefined);
}

test "test LightClientHeader" {
    const header = LightClientHeader{
        .phase0 = NonExistType{},
    };

    try std.testing.expectEqual(header.phase0, NonExistType{});

    const header1 = LightClientHeader{
        .altair = altair.LightClientHeader{
            .beacon = undefined,
        },
    };

    try std.testing.expectEqual(header1.altair.beacon, undefined);
}

test "test LightClientOptimisticUpdate" {
    const update = LightClientOptimisticUpdate{
        .phase0 = NonExistType{},
    };

    try std.testing.expectEqual(update.phase0, NonExistType{});

    const update1 = LightClientOptimisticUpdate{
        .altair = altair.LightClientOptimisticUpdate{
            .attested_header = undefined,
            .sync_aggregate = undefined,
            .signature_slot = 0,
        },
    };

    try std.testing.expectEqual(update1.altair.attested_header, undefined);
}

test "test LightClientFinalityUpdate" {
    const update = LightClientFinalityUpdate{
        .phase0 = NonExistType{},
    };

    try std.testing.expectEqual(update.phase0, NonExistType{});

    const finality_branch = primitives.FinalityBranch{
        .altair = [_][32]u8{
            [_]u8{0} ** 32,
        } ** 6,
    };

    const update1 = LightClientFinalityUpdate{
        .altair = altair.LightClientFinalityUpdate{
            .attested_header = undefined,
            .finalized_header = undefined,
            .finality_branch = finality_branch,
            .sync_aggregate = undefined,
            .signature_slot = 0,
        },
    };

    try std.testing.expectEqual(update1.altair.signature_slot, 0);
}

test "test LightClientUpdate" {
    const update = LightClientUpdate{
        .phase0 = NonExistType{},
    };

    try std.testing.expectEqual(update.phase0, NonExistType{});

    const next_sync_committee_branch = primitives.NextSyncCommitteeBranch{
        .altair = [_][32]u8{
            [_]u8{0} ** 32,
        } ** 5,
    };

    const finality_branch = primitives.FinalityBranch{
        .altair = [_][32]u8{
            [_]u8{0} ** 32,
        } ** 6,
    };

    const update1 = LightClientUpdate{
        .altair = altair.LightClientUpdate{
            .attested_header = undefined,
            .next_sync_committee = undefined,
            .next_sync_committee_branch = next_sync_committee_branch,
            .finalized_header = undefined,
            .finality_branch = finality_branch,
            .sync_aggregate = undefined,
            .signature_slot = 0,
        },
    };

    try std.testing.expectEqual(update1.altair.finality_branch.altair.len, 6);
}

test "test LightClientBootstrap" {
    const bootstrap = LightClientBootstrap{
        .phase0 = NonExistType{},
    };

    try std.testing.expectEqual(bootstrap.phase0, NonExistType{});

    const current_sync_committee_branch = primitives.CurrentSyncCommitteeBranch{
        .altair = [_][32]u8{
            [_]u8{0} ** 32,
        } ** 5,
    };

    const bootstrap1 = LightClientBootstrap{
        .altair = altair.LightClientBootstrap{
            .header = undefined,
            .current_sync_committee = undefined,
            .current_sync_committee_branch = current_sync_committee_branch,
        },
    };

    try std.testing.expectEqual(bootstrap1.altair.current_sync_committee_branch.altair.len, 5);
}

test "test PowBlock" {
    const block = PowBlock{
        .phase0 = NonExistType{},
    };

    try std.testing.expectEqual(block.phase0, NonExistType{});

    const block1 = PowBlock{
        .bellatrix = bellatrix.PowBlock{
            .block_hash = undefined,
            .parent_hash = undefined,
            .total_difficulty = 0,
        },
    };

    try std.testing.expectEqual(block1.bellatrix.total_difficulty, 0);
}

test "test Withdrawal" {
    const withdrawal = Withdrawal{
        .phase0 = NonExistType{},
    };

    try std.testing.expectEqual(withdrawal.phase0, NonExistType{});

    const withdrawal1 = Withdrawal{
        .capella = capella.Withdrawal{
            .index = 0,
            .validator_index = 0,
            .address = undefined,
            .amount = 0,
        },
    };

    try std.testing.expectEqual(withdrawal1.capella.index, 0);
}

test "test BLSToExecutionChange" {
    const change = BLSToExecutionChange{
        .phase0 = NonExistType{},
    };

    try std.testing.expectEqual(change.phase0, NonExistType{});

    const change1 = BLSToExecutionChange{
        .capella = capella.BLSToExecutionChange{
            .validator_index = 0,
            .from_bls_pubkey = undefined,
            .to_execution_address = undefined,
        },
    };

    try std.testing.expectEqual(change1.capella.validator_index, 0);
}

test "test SignedBLSToExecutionChange" {
    const change = SignedBLSToExecutionChange{
        .phase0 = NonExistType{},
    };

    try std.testing.expectEqual(change.phase0, NonExistType{});

    const change1 = SignedBLSToExecutionChange{
        .capella = capella.SignedBLSToExecutionChange{
            .message = undefined,
            .signature = undefined,
        },
    };

    try std.testing.expectEqual(change1.capella.message, undefined);
}

test "test HistoricalSummary" {
    const summary = HistoricalSummary{
        .capella = capella.HistoricalSummary{
            .block_summary_root = undefined,
            .state_summary_root = undefined,
        },
    };

    try std.testing.expectEqual(summary.capella.block_summary_root.len, 32);
}

test "test ExecutionPayload" {
    const payload = ExecutionPayload{
        .phase0 = NonExistType{},
    };

    try std.testing.expectEqual(payload.phase0, NonExistType{});

    const payload1 = ExecutionPayload{
        .capella = capella.ExecutionPayload{
            .parent_hash = undefined,
            .fee_recipient = undefined,
            .state_root = undefined,
            .receipts_root = undefined,
            .logs_bloom = undefined,
            .prev_randao = undefined,
            .block_number = 21,
            .gas_limit = 0,
            .gas_used = 0,
            .timestamp = 0,
            .extra_data = undefined,
            .base_fee_per_gas = 0,
            .block_hash = undefined,
            .transactions = undefined,
            .withdrawals = undefined,
        },
    };

    try std.testing.expectEqual(payload1.capella.block_number, 21);
}

test "test BlobSidecar" {
    const sidecar = BlobSidecar{
        .phase0 = NonExistType{},
    };

    try std.testing.expectEqual(sidecar.phase0, NonExistType{});

    const sidecar1 = BlobSidecar{
        .deneb = deneb.BlobSidecar{
            .index = 3,
            .blob = undefined,
            .kzg_commitment = undefined,
            .kzg_proof = undefined,
            .signed_block_header = undefined,
            .kzg_commitment_inclusion_proof = undefined,
        },
    };

    try std.testing.expectEqual(sidecar1.deneb.index, 3);
}

test "test BlobIdentifier" {
    const identifier = BlobIdentifier{
        .phase0 = NonExistType{},
    };

    try std.testing.expectEqual(identifier.phase0, NonExistType{});

    const identifier1 = BlobIdentifier{
        .deneb = deneb.BlobIdentifier{
            .block_root = undefined,
            .index = undefined,
        },
    };

    try std.testing.expectEqual(identifier1.deneb.block_root.len, 32);
}

test "test PendingConsolidation" {
    const consolidation = PendingConsolidation{
        .phase0 = NonExistType{},
    };

    try std.testing.expectEqual(consolidation.phase0, NonExistType{});

    const consolidation1 = PendingConsolidation{
        .electra = electra.PendingConsolidation{
            .source_index = 0,
            .target_index = 0,
        },
    };

    try std.testing.expectEqual(consolidation1.electra.source_index, 0);
}

test "test BeaconState" {
    const p0 = phase0.BeaconState{
        .genesis_time = 0,
        .genesis_validators_root = undefined,
        .slot = 0,
        .fork = undefined,
        .latest_block_header = undefined,
        .block_roots = undefined,
        .state_roots = undefined,
        .historical_roots = undefined,
        .eth1_data = undefined,
        .eth1_data_votes = undefined,
        .eth1_deposit_index = 0,
        .validators = undefined,
        .balances = undefined,
        .randao_mixes = undefined,
        .slashings = undefined,
        .previous_epoch_attestations = undefined,
        .current_epoch_attestations = undefined,
        .justification_bits = undefined,
        .previous_justified_checkpoint = undefined,
        .current_justified_checkpoint = undefined,
        .finalized_checkpoint = undefined,
    };

    const state = BeaconState{
        .phase0 = p0,
    };

    try std.testing.expectEqual(state.phase0.genesis_time, 0);
}

test "test Validator" {
    const validator = Validator{
        .pubkey = undefined,
        .withdrawal_credentials = undefined,
        .effective_balance = 0,
        .slashed = false,
        .activation_eligibility_epoch = 0,
        .activation_epoch = 0,
        .exit_epoch = 0,
        .withdrawable_epoch = 0,
    };

    try std.testing.expectEqual(validator.effective_balance, 0);
}

test "test SignedVoluntaryExit" {
    const exit = SignedVoluntaryExit{
        .message = undefined,
        .signature = undefined,
    };

    try std.testing.expectEqual(exit.message, undefined);
}
