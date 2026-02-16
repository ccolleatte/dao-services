export interface Database {
  public: {
    Tables: {
      missions: {
        Row: {
          id: number;
          client_wallet: string;
          budget_max_daos: string;
          on_chain_mission_id: string | null;
          budget_locked_daos: string | null;
          created_at: string;
          status: string;
          selected_consultant_wallet: string | null;
        };
        Insert: {
          id?: number;
          client_wallet: string;
          budget_max_daos: string;
          on_chain_mission_id?: string | null;
          budget_locked_daos?: string | null;
          created_at?: string;
          status?: string;
          selected_consultant_wallet?: string | null;
        };
        Update: {
          id?: number;
          client_wallet?: string;
          budget_max_daos?: string;
          on_chain_mission_id?: string | null;
          budget_locked_daos?: string | null;
          created_at?: string;
          status?: string;
          selected_consultant_wallet?: string | null;
        };
      };
      applications: {
        Row: {
          id: number;
          mission_id: number;
          consultant_wallet: string;
          match_score: number;
          created_at: string;
        };
        Insert: {
          id?: number;
          mission_id: number;
          consultant_wallet: string;
          match_score?: number;
          created_at?: string;
        };
        Update: {
          id?: number;
          mission_id?: number;
          consultant_wallet?: string;
          match_score?: number;
          created_at?: string;
        };
      };
      mission_applications: {
        Row: {
          id: number;
          mission_id: number;
          consultant_wallet: string;
          status: string;
          match_score: number;
          created_at: string;
        };
        Insert: {
          id?: number;
          mission_id: number;
          consultant_wallet: string;
          status?: string;
          match_score?: number;
          created_at?: string;
        };
        Update: {
          id?: number;
          mission_id?: number;
          consultant_wallet?: string;
          status?: string;
          match_score?: number;
          created_at?: string;
        };
      };
      notifications: {
        Row: {
          id: number;
          recipient_wallet: string;
          notification_type: string;
          title: string;
          message: string;
          link_url: string;
          metadata: any;
          created_at: string;
        };
        Insert: {
          id?: number;
          recipient_wallet: string;
          notification_type: string;
          title: string;
          message: string;
          link_url: string;
          metadata?: any;
          created_at?: string;
        };
        Update: {
          id?: number;
          recipient_wallet?: string;
          notification_type?: string;
          title?: string;
          message?: string;
          link_url?: string;
          metadata?: any;
          created_at?: string;
        };
      };
      payments: {
        Row: {
          id: number;
          mission_id: number;
          recipient_wallet: string;
          amount_daos: string;
          contributor_type: string;
          milestone_id: number | null;
          transaction_hash: string;
          created_at: string;
        };
        Insert: {
          id?: number;
          mission_id: number;
          recipient_wallet: string;
          amount_daos: string;
          contributor_type: string;
          milestone_id?: number | null;
          transaction_hash: string;
          created_at?: string;
        };
        Update: {
          id?: number;
          mission_id?: number;
          recipient_wallet?: string;
          amount_daos?: string;
          contributor_type?: string;
          milestone_id?: number | null;
          transaction_hash?: string;
          created_at?: string;
        };
      };
      milestones: {
        Row: {
          id: number;
          mission_id: number;
          status: string;
          approved_at: string | null;
          created_at: string;
        };
        Insert: {
          id?: number;
          mission_id: number;
          status?: string;
          approved_at?: string | null;
          created_at?: string;
        };
        Update: {
          id?: number;
          mission_id?: number;
          status?: string;
          approved_at?: string | null;
          created_at?: string;
        };
      };
      disputes: {
        Row: {
          id: number;
          on_chain_dispute_id: string;
          milestone_id: number;
          mission_id: number;
          initiator_wallet: string;
          reason: string;
          status: string;
          voting_deadline: string;
          created_at: string;
        };
        Insert: {
          id?: number;
          on_chain_dispute_id: string;
          milestone_id: number;
          mission_id: number;
          initiator_wallet: string;
          reason: string;
          status?: string;
          voting_deadline: string;
          created_at?: string;
        };
        Update: {
          id?: number;
          on_chain_dispute_id?: string;
          milestone_id?: number;
          mission_id?: number;
          initiator_wallet?: string;
          reason?: string;
          status?: string;
          voting_deadline?: string;
          created_at?: string;
        };
      };
      blockchain_transactions: {
        Row: {
          id: number;
          transaction_hash: string;
          block_number: number;
          transaction_type: string;
          contract_address: string;
          event_name: string;
          event_data: any;
          mission_id: number | null;
          created_at: string;
        };
        Insert: {
          id?: number;
          transaction_hash: string;
          block_number: number;
          transaction_type: string;
          contract_address: string;
          event_name: string;
          event_data: any;
          mission_id?: number | null;
          created_at?: string;
        };
        Update: {
          id?: number;
          transaction_hash?: string;
          block_number?: number;
          transaction_type?: string;
          contract_address?: string;
          event_name?: string;
          event_data?: any;
          mission_id?: number | null;
          created_at?: string;
        };
      };
    };
    Views: {};
    Functions: {};
    Enums: {};
  };
}
