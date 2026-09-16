# OTOBO config file (automatically generated)
# VERSION:1.1
package Kernel::Config::Files::ZZZProcessManagement;
use strict;
use warnings;
no warnings 'redefine'; ## no critic qw(TestingAndDebugging::ProhibitNoWarnings)
use utf8;
sub Load {
    my ($File, $Self) = @_;
$Self->{'Process'} = {
  'Process-44258576c8e8bc5e7290607746956473' => {
    'ChangeTime' => '2026-06-02 08:00:00',
    'CreateTime' => '2026-05-19 06:44:01',
    'Name' => 'ztsm-ticket-lifecycle-ochestration',
    'Path' => {
      'Activity-2c9b289d02d2935550df191c986e2bb8' => {
        'Transition-62f721d77000b8a55ffcd36fd50ee25e' => {
          'ActivityEntityID' => 'Activity-7ae5a5a1d78eed43c2c718facb3eae65'
        }
      },
      'Activity-34165120277c0bacb81ab0d4238c37d8' => {
        'Transition-04744060f9f24ba6ecf9e31e7b3bd54a' => {
          'ActivityEntityID' => 'Activity-a08597b234bbccf5791c588eb7eb904d',
          'TransitionAction' => [
            'TransitionAction-86d1455359a643cefdf2176a7194c0fe'
          ]
        }
      },
      'Activity-7ae5a5a1d78eed43c2c718facb3eae65' => {
        'Transition-530b2bb23669e9ddd10dbf6f11d73b67' => {
          'ActivityEntityID' => 'Activity-a08597b234bbccf5791c588eb7eb904d',
          'TransitionAction' => [
            'TransitionAction-ab713b9f7dbf3a77e7314a6bd6da5e6d'
          ]
        },
        'Transition-79a9beb15c36092f1be847504957ad37' => {
          'ActivityEntityID' => 'Activity-2c9b289d02d2935550df191c986e2bb8',
          'TransitionAction' => [
            'TransitionAction-0b71e4ec234707e58f9557faf6ad1fb8'
          ]
        }
      },
      'Activity-a08597b234bbccf5791c588eb7eb904d' => {
        'Transition-daf4722965429ec766dc1edacb18ae3f' => {
          'ActivityEntityID' => 'Activity-b83380fe3605688f475b6a0cc8a94085',
          'TransitionAction' => [
            'TransitionAction-7564ca7dec5ec71f214a555bd6f1f055'
          ]
        }
      },
      'Activity-b83380fe3605688f475b6a0cc8a94085' => {
        'Transition-3d843ca4f50c50443595ca689fce2c58' => {
          'ActivityEntityID' => 'Activity-2c9b289d02d2935550df191c986e2bb8',
          'TransitionAction' => [
            'TransitionAction-baa9deeea687c519eb9b4141f89f94dc'
          ]
        }
      }
    },
    'StartActivity' => 'Activity-34165120277c0bacb81ab0d4238c37d8',
    'StartActivityDialog' => 'ActivityDialog-0531e22886a9fb00153f49f4dfa56ab6',
    'State' => 'Active',
    'StateEntityID' => 'S1'
  },
  'Process-56e14e3e17947e7d18d16e910aa2b91f' => {
    'ChangeTime' => '2026-05-14 07:57:40',
    'CreateTime' => '2026-04-15 07:13:02',
    'Name' => 'ServiceRequest',
    'Path' => {
      'Activity-205ca4c18ccf33d0badc3b76f0e5aeef' => {
        'Transition-623ec4e8437c55da1079cac3288ed53b' => {
          'ActivityEntityID' => 'Activity-2b72863a53a2df2def0ae5cbe0f99cb1',
          'TransitionAction' => [
            'TransitionAction-eaaee915ae0a9ba4a4c826110d190e2f'
          ]
        }
      },
      'Activity-2b72863a53a2df2def0ae5cbe0f99cb1' => {},
      'Activity-cb6b501496edb6ea906fa7c85b329f07' => {
        'Transition-dcfede9b6358dcff83bb35125553425d' => {
          'ActivityEntityID' => 'Activity-205ca4c18ccf33d0badc3b76f0e5aeef',
          'TransitionAction' => [
            'TransitionAction-daa0e7534537ea4ee4427ed48041fbdc'
          ]
        }
      }
    },
    'StartActivity' => 'Activity-cb6b501496edb6ea906fa7c85b329f07',
    'StartActivityDialog' => 'ActivityDialog-89fd21ddc3fd1c5d4e5b19d7a690f7dc',
    'State' => 'Active',
    'StateEntityID' => 'S1'
  },
  'Process-f591d39e4cefb1b9e16207b0f1f249b8' => {
    'ChangeTime' => '2026-06-02 08:25:22',
    'CreateTime' => '2026-05-19 08:02:57',
    'Name' => 'ztsm-activity-lifecycle-orchestration',
    'Path' => {
      'Activity-34165120277c0bacb81ab0d4238c37d8' => {
        'Transition-73986cfe5c9d1f052a8801de90639d39' => {
          'ActivityEntityID' => 'Activity-d03ebeeb1fe92dc4ed1ddbb9d6e5a8b1',
          'TransitionAction' => [
            'TransitionAction-c2fc5b9b5a445ffc0d00a18a068c4b6f'
          ]
        }
      },
      'Activity-423fffb8cdf2b78ca99648eea844990a' => {},
      'Activity-bb9a72021794a05b1987ad5d19cede4d' => {
        'Transition-c85842060cd288f31c26b7055433e59b' => {
          'ActivityEntityID' => 'Activity-423fffb8cdf2b78ca99648eea844990a',
          'TransitionAction' => [
            'TransitionAction-76049985f97045be0504eeea395c711b'
          ]
        }
      },
      'Activity-d03ebeeb1fe92dc4ed1ddbb9d6e5a8b1' => {
        'Transition-3307fab7725f8178910dde7b308e3aca' => {
          'ActivityEntityID' => 'Activity-bb9a72021794a05b1987ad5d19cede4d',
          'TransitionAction' => [
            'TransitionAction-0a9c66ff63d6d8d1d0b924d0138d3d31'
          ]
        }
      }
    },
    'StartActivity' => 'Activity-34165120277c0bacb81ab0d4238c37d8',
    'StartActivityDialog' => 'ActivityDialog-0531e22886a9fb00153f49f4dfa56ab6',
    'State' => 'Active',
    'StateEntityID' => 'S1'
  }
};

$Self->{'Process::State'} = {
  'S1' => 'Active',
  'S2' => 'Inactive',
  'S3' => 'FadeAway'
};

$Self->{'Process::Activity'} = {
  'Activity-0fccdef3b2364137178ef15eb25682e0' => {
    'ActivityDialog' => '',
    'ChangeTime' => '2026-05-13 03:23:19',
    'CreateTime' => '2026-05-13 03:23:19',
    'ID' => 4,
    'Name' => 'Endorsement'
  },
  'Activity-205ca4c18ccf33d0badc3b76f0e5aeef' => {
    'ActivityDialog' => {
      '1' => 'ActivityDialog-34db70f1fce711773ca402199d96ef93'
    },
    'ChangeTime' => '2026-05-13 03:23:00',
    'CreateTime' => '2026-04-15 07:56:08',
    'ID' => 1,
    'Name' => 'Validate'
  },
  'Activity-2b72863a53a2df2def0ae5cbe0f99cb1' => {
    'ActivityDialog' => '',
    'ChangeTime' => '2026-05-14 04:06:26',
    'CreateTime' => '2026-05-14 04:06:26',
    'ID' => 9,
    'Name' => 'Assessment'
  },
  'Activity-2c9b289d02d2935550df191c986e2bb8' => {
    'ActivityDialog' => {
      '1' => 'ActivityDialog-0531e22886a9fb00153f49f4dfa56ab6'
    },
    'ChangeTime' => '2026-06-02 02:48:47',
    'CreateTime' => '2026-06-02 02:48:47',
    'ID' => 17,
    'Name' => 'BlueBook Reader - 2'
  },
  'Activity-34165120277c0bacb81ab0d4238c37d8' => {
    'ActivityDialog' => {
      '1' => 'ActivityDialog-0531e22886a9fb00153f49f4dfa56ab6'
    },
    'ChangeTime' => '2026-05-19 07:08:29',
    'CreateTime' => '2026-05-19 06:48:53',
    'ID' => 10,
    'Name' => 'Start'
  },
  'Activity-3ddc893071e488797cb152edbb5baad6' => {
    'ActivityDialog' => '',
    'ChangeTime' => '2026-05-13 03:25:16',
    'CreateTime' => '2026-05-13 03:25:16',
    'ID' => 7,
    'Name' => 'Verification'
  },
  'Activity-423fffb8cdf2b78ca99648eea844990a' => {
    'ActivityDialog' => {
      '1' => 'ActivityDialog-0531e22886a9fb00153f49f4dfa56ab6'
    },
    'ChangeTime' => '2026-06-02 08:18:51',
    'CreateTime' => '2026-05-19 08:08:52',
    'ID' => 14,
    'Name' => 'ChapterDirector'
  },
  'Activity-6cfb0a8533e82409664c98a0bb857ace' => {
    'ActivityDialog' => '',
    'ChangeTime' => '2026-05-13 03:23:52',
    'CreateTime' => '2026-05-13 03:23:52',
    'ID' => 5,
    'Name' => 'Approval'
  },
  'Activity-7ae5a5a1d78eed43c2c718facb3eae65' => {
    'ActivityDialog' => {
      '1' => 'ActivityDialog-0531e22886a9fb00153f49f4dfa56ab6'
    },
    'ChangeTime' => '2026-06-02 02:41:06',
    'CreateTime' => '2026-06-02 02:41:06',
    'ID' => 16,
    'Name' => 'BlueBook Director'
  },
  'Activity-a08597b234bbccf5791c588eb7eb904d' => {
    'ActivityDialog' => {
      '1' => 'ActivityDialog-0531e22886a9fb00153f49f4dfa56ab6'
    },
    'ChangeTime' => '2026-05-29 07:27:10',
    'CreateTime' => '2026-05-19 07:09:33',
    'ID' => 11,
    'Name' => 'StateBook Reader'
  },
  'Activity-b83380fe3605688f475b6a0cc8a94085' => {
    'ActivityDialog' => {
      '1' => 'ActivityDialog-0531e22886a9fb00153f49f4dfa56ab6'
    },
    'ChangeTime' => '2026-05-29 06:31:19',
    'CreateTime' => '2026-05-19 07:12:24',
    'ID' => 12,
    'Name' => 'BlueBook Reader'
  },
  'Activity-bb117ed78c9372375fa79e65533644d1' => {
    'ActivityDialog' => '',
    'ChangeTime' => '2026-05-13 03:24:16',
    'CreateTime' => '2026-05-13 03:24:16',
    'ID' => 6,
    'Name' => 'Implementation'
  },
  'Activity-bb9a72021794a05b1987ad5d19cede4d' => {
    'ActivityDialog' => {
      '1' => 'ActivityDialog-0531e22886a9fb00153f49f4dfa56ab6'
    },
    'ChangeTime' => '2026-06-02 08:23:15',
    'CreateTime' => '2026-06-02 08:23:15',
    'ID' => 18,
    'Name' => 'Activity-InProgress'
  },
  'Activity-cb38901550faadf19a997fe8f800316c' => {
    'ActivityDialog' => '',
    'ChangeTime' => '2026-05-19 08:09:56',
    'CreateTime' => '2026-05-19 08:09:56',
    'ID' => 15,
    'Name' => 'Activity-Closure'
  },
  'Activity-cb6b501496edb6ea906fa7c85b329f07' => {
    'ActivityDialog' => {
      '1' => 'ActivityDialog-89fd21ddc3fd1c5d4e5b19d7a690f7dc'
    },
    'ChangeTime' => '2026-05-14 07:57:32',
    'CreateTime' => '2026-04-15 08:55:19',
    'ID' => 3,
    'Name' => 'New'
  },
  'Activity-d03ebeeb1fe92dc4ed1ddbb9d6e5a8b1' => {
    'ActivityDialog' => {
      '1' => 'ActivityDialog-0531e22886a9fb00153f49f4dfa56ab6'
    },
    'ChangeTime' => '2026-06-02 08:18:19',
    'CreateTime' => '2026-05-19 08:04:16',
    'ID' => 13,
    'Name' => 'Activity-Engage'
  },
  'Activity-f74ba30ac1bb0a3881c0f7793f3eac74' => {
    'ActivityDialog' => {
      '1' => 'ActivityDialog-0531e22886a9fb00153f49f4dfa56ab6'
    },
    'ChangeTime' => '2026-05-19 07:14:25',
    'CreateTime' => '2026-05-13 03:26:36',
    'ID' => 8,
    'Name' => 'End'
  }
};

$Self->{'Process::ActivityDialog'} = {
  'ActivityDialog-0531e22886a9fb00153f49f4dfa56ab6' => {
    'ChangeTime' => '2026-07-14 01:52:52',
    'CreateTime' => '2026-05-19 07:06:57',
    'DescriptionLong' => 'Empty Process Dialog',
    'DescriptionShort' => 'Empty Process Dialog',
    'DirectSubmit' => '1',
    'FieldOrder' => [],
    'Fields' => {},
    'InputFieldDefinition' => '',
    'Interface' => [
      'AgentInterface',
      'CustomerInterface'
    ],
    'Name' => 'return',
    'Permission' => 'owner',
    'RequiredLock' => '',
    'SubmitAdviceText' => '',
    'SubmitButtonText' => ''
  },
  'ActivityDialog-13b48aaf5c0b896a78619d4775976741' => {
    'ChangeTime' => '2026-05-29 06:20:03',
    'CreateTime' => '2026-05-29 06:14:11',
    'DescriptionLong' => '',
    'DescriptionShort' => 'Statebook Reader',
    'DirectSubmit' => '1',
    'FieldOrder' => [
      'DynamicField_FirewallPolicyRule'
    ],
    'Fields' => {
      'DynamicField_FirewallPolicyRule' => {
        'DefaultValue' => '',
        'DescriptionLong' => '',
        'DescriptionShort' => '',
        'Display' => '1'
      }
    },
    'InputFieldDefinition' => '',
    'Interface' => [
      'AgentInterface',
      'CustomerInterface'
    ],
    'Name' => 'StateBook Reader',
    'Permission' => 'owner',
    'RequiredLock' => '',
    'SubmitAdviceText' => '',
    'SubmitButtonText' => 'Submit'
  },
  'ActivityDialog-34db70f1fce711773ca402199d96ef93' => {
    'ChangeTime' => '2026-05-13 04:22:38',
    'CreateTime' => '2026-04-15 08:45:21',
    'DescriptionLong' => 'IPC to validate request before assessment.:
Project, Location, and Service for Assessment routing',
    'DescriptionShort' => 'Validate request completeness and correctness',
    'DirectSubmit' => 0,
    'FieldOrder' => [
      'Type',
      'Service',
      'DynamicField_ZTicket-Application',
      'DynamicField_ZTicket-Env',
      'DynamicField_ZTicket-Location'
    ],
    'Fields' => {
      'DynamicField_ZTicket-Application' => {
        'DefaultValue' => '',
        'DescriptionLong' => 'Application System, leave empty if it was new project',
        'DescriptionShort' => 'Application System',
        'Display' => '1'
      },
      'DynamicField_ZTicket-Env' => {
        'DefaultValue' => '',
        'DescriptionLong' => 'Environment',
        'DescriptionShort' => 'Environment',
        'Display' => '1'
      },
      'DynamicField_ZTicket-Location' => {
        'DefaultValue' => '',
        'DescriptionLong' => 'Location',
        'DescriptionShort' => 'Location',
        'Display' => '1'
      },
      'Service' => {
        'DefaultValue' => '',
        'DescriptionLong' => 'Service Offering',
        'DescriptionShort' => 'Service',
        'Display' => '1'
      },
      'Type' => {
        'DefaultValue' => '',
        'DescriptionLong' => '',
        'DescriptionShort' => 'Type',
        'Display' => '2'
      }
    },
    'InputFieldDefinition' => '',
    'Interface' => [
      'AgentInterface',
      'CustomerInterface'
    ],
    'Name' => 'Validate',
    'Permission' => 'move_into',
    'RequiredLock' => '',
    'SubmitAdviceText' => 'Please ensure Application System reflect correctly',
    'SubmitButtonText' => 'Validate'
  },
  'ActivityDialog-7f750cea19eed913f55a829b6b732c48' => {
    'ChangeTime' => '2026-05-13 04:32:49',
    'CreateTime' => '2026-05-13 04:32:49',
    'DescriptionLong' => '',
    'DescriptionShort' => 'Impact Assessment',
    'DirectSubmit' => 0,
    'FieldOrder' => [],
    'Fields' => {},
    'InputFieldDefinition' => '',
    'Interface' => [
      'AgentInterface',
      'CustomerInterface'
    ],
    'Name' => 'Assessment',
    'Permission' => 'rw',
    'RequiredLock' => '',
    'SubmitAdviceText' => 'Submit Assessment Score',
    'SubmitButtonText' => 'Assess'
  },
  'ActivityDialog-89fd21ddc3fd1c5d4e5b19d7a690f7dc' => {
    'ChangeTime' => '2026-05-14 07:57:11',
    'CreateTime' => '2026-05-14 07:57:11',
    'DescriptionLong' => 'New SR Ticket',
    'DescriptionShort' => 'New SR Ticket',
    'DirectSubmit' => '1',
    'FieldOrder' => [],
    'Fields' => {},
    'InputFieldDefinition' => '',
    'Interface' => [
      'AgentInterface',
      'CustomerInterface'
    ],
    'Name' => 'New SR',
    'Permission' => '',
    'RequiredLock' => '',
    'SubmitAdviceText' => '',
    'SubmitButtonText' => ''
  },
  'ActivityDialog-b3248b9c151b3775fc51d60326803266' => {
    'ChangeTime' => '2026-04-15 09:03:23',
    'CreateTime' => '2026-04-15 08:58:26',
    'DescriptionLong' => 'Submit Ticket',
    'DescriptionShort' => 'Ticket Submission',
    'DirectSubmit' => 0,
    'FieldOrder' => [
      'CustomerID',
      'Type',
      'Service',
      'DynamicField_TicketAppSystem',
      'DynamicField_TicketEnvironment',
      'DynamicField_TicketLocation',
      'DynamicField_FirewallPolicyRule'
    ],
    'Fields' => {
      'CustomerID' => {
        'DefaultValue' => '',
        'DescriptionLong' => '',
        'DescriptionShort' => '',
        'Display' => '2'
      },
      'DynamicField_FirewallPolicyRule' => {
        'DefaultValue' => '',
        'DescriptionLong' => '',
        'DescriptionShort' => '',
        'Display' => '1'
      },
      'DynamicField_TicketAppSystem' => {
        'DefaultValue' => '',
        'DescriptionLong' => '',
        'DescriptionShort' => '',
        'Display' => '2'
      },
      'DynamicField_TicketEnvironment' => {
        'DefaultValue' => '',
        'DescriptionLong' => '',
        'DescriptionShort' => '',
        'Display' => '2'
      },
      'DynamicField_TicketLocation' => {
        'DefaultValue' => '',
        'DescriptionLong' => '',
        'DescriptionShort' => '',
        'Display' => '2'
      },
      'Service' => {
        'DefaultValue' => '',
        'DescriptionLong' => '',
        'DescriptionShort' => '',
        'Display' => '2'
      },
      'Type' => {
        'DefaultValue' => '',
        'DescriptionLong' => '',
        'DescriptionShort' => '',
        'Display' => '2'
      }
    },
    'InputFieldDefinition' => '',
    'Interface' => [
      'AgentInterface',
      'CustomerInterface'
    ],
    'Name' => 'Ticket Submission',
    'Permission' => '',
    'RequiredLock' => '',
    'SubmitAdviceText' => '',
    'SubmitButtonText' => 'Submit'
  },
  'ActivityDialog-ddc135485a4fcedfa066001607bcc312' => {
    'ChangeTime' => '2026-05-14 06:43:09',
    'CreateTime' => '2026-05-14 06:43:09',
    'DescriptionLong' => 'New Firewall Request',
    'DescriptionShort' => 'New Firewall Request',
    'DirectSubmit' => 0,
    'FieldOrder' => [
      'Title',
      'Type',
      'Service',
      'DynamicField_FirewallPolicyRule'
    ],
    'Fields' => {
      'DynamicField_FirewallPolicyRule' => {
        'DefaultValue' => '',
        'DescriptionLong' => '',
        'DescriptionShort' => 'Firewall Policy',
        'Display' => '1'
      },
      'Service' => {
        'DefaultValue' => '',
        'DescriptionLong' => '',
        'DescriptionShort' => '',
        'Display' => '2'
      },
      'Title' => {
        'DefaultValue' => '',
        'DescriptionLong' => '',
        'DescriptionShort' => '',
        'Display' => '1'
      },
      'Type' => {
        'DefaultValue' => '',
        'DescriptionLong' => '',
        'DescriptionShort' => '',
        'Display' => '2'
      }
    },
    'InputFieldDefinition' => '',
    'Interface' => [
      'AgentInterface',
      'CustomerInterface'
    ],
    'Name' => 'New Firewall SR',
    'Permission' => '',
    'RequiredLock' => '',
    'SubmitAdviceText' => 'Submit Firewall Request',
    'SubmitButtonText' => 'Submit'
  }
};

$Self->{'Process::Transition'} = {
  'Transition-04744060f9f24ba6ecf9e31e7b3bd54a' => {
    'ChangeTime' => '2026-05-19 07:17:31',
    'Condition' => {
      '1' => {
        'Fields' => {
          'State' => {
            'Match' => 'new',
            'Type' => 'String'
          }
        },
        'Type' => 'and'
      }
    },
    'ConditionLinking' => 'and',
    'CreateTime' => '2026-05-19 07:17:31',
    'Name' => 'new_to_step_in_statebook'
  },
  'Transition-1591e474e042ee46453c3af941cf2f04' => {
    'ChangeTime' => '2026-05-19 08:15:35',
    'Condition' => {
      '1' => {
        'Fields' => {
          'State' => {
            'Match' => 'new',
            'Type' => 'Module'
          }
        },
        'Type' => 'xor'
      }
    },
    'ConditionLinking' => 'and',
    'CreateTime' => '2026-05-19 08:14:21',
    'Name' => 'step-in-bluebook'
  },
  'Transition-3307fab7725f8178910dde7b308e3aca' => {
    'ChangeTime' => '2026-05-28 04:56:41',
    'Condition' => {
      '1' => {
        'Fields' => {
          'State' => {
            'Match' => 'Pending',
            'Type' => 'String'
          }
        },
        'Type' => 'and'
      },
      '2' => {
        'Fields' => {
          'ZTicket-Owner' => {
            'Match' => '^ [A-Za-z0-9\\-] +$',
            'Type' => 'Regexp'
          }
        },
        'Type' => 'and'
      }
    },
    'ConditionLinking' => 'and',
    'CreateTime' => '2026-05-28 04:54:27',
    'Name' => 'work-inprogress'
  },
  'Transition-3d843ca4f50c50443595ca689fce2c58' => {
    'ChangeTime' => '2026-06-02 02:50:08',
    'Condition' => {
      '1' => {
        'Fields' => {
          'StateType' => {
            'Match' => 'new',
            'Type' => 'String'
          }
        },
        'Type' => 'xor'
      },
      '2' => {
        'Fields' => {
          'StateType' => {
            'Match' => 'open',
            'Type' => 'String'
          }
        },
        'Type' => 'and'
      },
      '3' => {
        'Fields' => {
          'StateType' => {
            'Match' => 'pending',
            'Type' => 'String'
          }
        },
        'Type' => 'and'
      }
    },
    'ConditionLinking' => 'and',
    'CreateTime' => '2026-05-19 07:26:26',
    'Name' => 'bluebook_step_up'
  },
  'Transition-530b2bb23669e9ddd10dbf6f11d73b67' => {
    'ChangeTime' => '2026-06-02 02:57:54',
    'Condition' => {
      '1' => {
        'Fields' => {
          'TicketID' => {
            'Match' => 'Kernel::System::ProcessManagement::TransitionValidation::ZTSMBlueBookComplete',
            'Type' => 'Module'
          }
        },
        'Type' => 'and'
      }
    },
    'ConditionLinking' => 'and',
    'CreateTime' => '2026-06-02 02:57:54',
    'Name' => 'BlueBook Complete'
  },
  'Transition-54a61cf289a7b6bfa900d5dd1e6836b3' => {
    'ChangeTime' => '2026-06-02 02:55:15',
    'Condition' => {
      '1' => {
        'Fields' => {
          'StateType' => {
            'Match' => 'open',
            'Type' => 'String'
          }
        },
        'Type' => 'and'
      },
      '2' => {
        'Fields' => {
          'StateType' => {
            'Match' => 'new',
            'Type' => 'String'
          }
        },
        'Type' => 'and'
      },
      '3' => {
        'Fields' => {
          'StateType' => {
            'Match' => 'pending',
            'Type' => 'String'
          }
        },
        'Type' => 'and'
      }
    },
    'ConditionLinking' => 'and',
    'CreateTime' => '2026-06-02 02:55:15',
    'Name' => 'loop-bluebook'
  },
  'Transition-623ec4e8437c55da1079cac3288ed53b' => {
    'ChangeTime' => '2026-05-14 06:05:22',
    'Condition' => {
      '1' => {
        'Fields' => {
          'State' => {
            'Match' => 'validate',
            'Type' => 'String'
          }
        },
        'Type' => 'and'
      }
    },
    'ConditionLinking' => 'and',
    'CreateTime' => '2026-05-13 04:26:48',
    'Name' => 'validate_to_assess'
  },
  'Transition-62f721d77000b8a55ffcd36fd50ee25e' => {
    'ChangeTime' => '2026-06-02 02:44:56',
    'Condition' => {
      '1' => {
        'Fields' => {
          'TicketID' => {
            'Match' => 'Kernel::System::ProcessManagement::TransitionValidation::ZTSMBlueBookComplete',
            'Type' => 'Module'
          }
        },
        'Type' => 'and'
      }
    },
    'ConditionLinking' => 'and',
    'CreateTime' => '2026-06-02 02:44:56',
    'Name' => 'BlueLevel Completion'
  },
  'Transition-73986cfe5c9d1f052a8801de90639d39' => {
    'ChangeTime' => '2026-05-19 08:12:53',
    'Condition' => {
      '1' => {
        'Fields' => {
          'State' => {
            'Match' => 'new',
            'Type' => 'String'
          }
        },
        'Type' => 'and'
      }
    },
    'ConditionLinking' => 'and',
    'CreateTime' => '2026-05-19 08:12:53',
    'Name' => 'new_to_pending'
  },
  'Transition-79a9beb15c36092f1be847504957ad37' => {
    'ChangeTime' => '2026-06-02 03:01:45',
    'Condition' => {
      '1' => {
        'Fields' => {
          'TicketID' => {
            'Match' => 'Kernel::System::ProcessManagement::TransitionValidation::ZTSMBlueBookHasNextLevel',
            'Type' => 'Module'
          }
        },
        'Type' => 'and'
      }
    },
    'ConditionLinking' => 'and',
    'CreateTime' => '2026-06-02 03:01:45',
    'Name' => 'BlueBook Has Next Level'
  },
  'Transition-c85842060cd288f31c26b7055433e59b' => {
    'ChangeTime' => '2026-06-02 08:21:51',
    'Condition' => {
      '1' => {
        'Fields' => {
          'StateType' => {
            'Match' => 'closed',
            'Type' => 'String'
          }
        },
        'Type' => 'and'
      }
    },
    'ConditionLinking' => 'and',
    'CreateTime' => '2026-05-19 08:16:58',
    'Name' => 'activity_exit'
  },
  'Transition-daf4722965429ec766dc1edacb18ae3f' => {
    'ChangeTime' => '2026-05-29 07:51:32',
    'Condition' => {
      '1' => {
        'Fields' => {
          'StateType' => {
            'Match' => 'open',
            'Type' => 'String'
          }
        },
        'Type' => 'or'
      },
      '2' => {
        'Fields' => {
          'StateType' => {
            'Match' => 'new',
            'Type' => 'String'
          }
        },
        'Type' => 'or'
      },
      '3' => {
        'Fields' => {
          'StateType' => {
            'Match' => 'pending',
            'Type' => 'String'
          }
        },
        'Type' => 'or'
      }
    },
    'ConditionLinking' => 'or',
    'CreateTime' => '2026-05-19 07:22:46',
    'Name' => 'statebook_walk_down'
  },
  'Transition-dcfede9b6358dcff83bb35125553425d' => {
    'ChangeTime' => '2026-05-14 06:04:15',
    'Condition' => {
      '1' => {
        'Fields' => {
          'State' => {
            'Match' => 'new',
            'Type' => 'String'
          }
        },
        'Type' => 'and'
      },
      '2' => {
        'Fields' => {
          'Type' => {
            'Match' => 'ServiceRequest',
            'Type' => 'String'
          }
        },
        'Type' => 'and'
      }
    },
    'ConditionLinking' => 'and',
    'CreateTime' => '2026-05-13 04:09:52',
    'Name' => 'Initial_State'
  }
};

$Self->{'Process::TransitionAction'} = {
  'TransitionAction-0a9c66ff63d6d8d1d0b924d0138d3d31' => {
    'ChangeTime' => '2026-05-28 04:49:47',
    'Config' => {
      '' => ''
    },
    'CreateTime' => '2026-05-28 04:49:47',
    'Module' => 'Kernel::System::ProcessManagement::TransitionAction::ZTSMCharacterEngage',
    'Name' => 'TESSERA-ChapterEngage'
  },
  'TransitionAction-0b71e4ec234707e58f9557faf6ad1fb8' => {
    'ChangeTime' => '2026-06-02 02:53:35',
    'Config' => {
      '' => ''
    },
    'CreateTime' => '2026-06-02 02:53:35',
    'Module' => 'Kernel::System::ProcessManagement::TransitionAction::ZTSMBlueBookDirector',
    'Name' => 'TESSERA-BlueBookDirector'
  },
  'TransitionAction-6c0450f3dae3fe3c33d3e326ad8a7c3d' => {
    'ChangeTime' => '2026-04-15 08:50:20',
    'Config' => {
      'State' => 'rejected'
    },
    'CreateTime' => '2026-04-15 08:50:20',
    'Module' => 'Kernel::System::ProcessManagement::TransitionAction::TicketStateSet',
    'Name' => 'MoveRejected'
  },
  'TransitionAction-7564ca7dec5ec71f214a555bd6f1f055' => {
    'ChangeTime' => '2026-05-28 04:21:24',
    'Config' => {
      '' => ''
    },
    'CreateTime' => '2026-05-28 04:21:24',
    'Module' => 'Kernel::System::ProcessManagement::TransitionAction::ZTSMStateBookReader',
    'Name' => 'TESSERA-StateBookReader'
  },
  'TransitionAction-76049985f97045be0504eeea395c711b' => {
    'ChangeTime' => '2026-05-28 04:49:28',
    'Config' => {
      '' => ''
    },
    'CreateTime' => '2026-05-28 04:49:28',
    'Module' => 'Kernel::System::ProcessManagement::TransitionAction::ZTSMChapterDirector',
    'Name' => 'TESSERA-ChapterDirector'
  },
  'TransitionAction-808e56248f5bdb904401bbfb263129e3' => {
    'ChangeTime' => '2026-05-28 04:48:56',
    'Config' => {
      '' => ''
    },
    'CreateTime' => '2026-05-28 04:48:56',
    'Module' => 'Kernel::System::ProcessManagement::TransitionAction::ZTSMRoleDirector',
    'Name' => 'TESSERA-RoleDirector'
  },
  'TransitionAction-86d1455359a643cefdf2176a7194c0fe' => {
    'ChangeTime' => '2026-05-28 04:20:57',
    'Config' => {
      '' => ''
    },
    'CreateTime' => '2026-05-28 04:20:57',
    'Module' => 'Kernel::System::ProcessManagement::TransitionAction::ZTSMServiceLibrarian',
    'Name' => 'TESSERA-ServiceLibrarian'
  },
  'TransitionAction-98b64a061a524484d994850e6805b64f' => {
    'ChangeTime' => '2026-04-15 08:51:48',
    'Config' => {
      'State' => 'verify'
    },
    'CreateTime' => '2026-04-15 08:51:48',
    'Module' => 'Kernel::System::ProcessManagement::TransitionAction::TicketStateSet',
    'Name' => 'MoveVerify'
  },
  'TransitionAction-ab713b9f7dbf3a77e7314a6bd6da5e6d' => {
    'ChangeTime' => '2026-06-02 07:59:38',
    'Config' => {
      '' => ''
    },
    'CreateTime' => '2026-06-02 07:59:38',
    'Module' => 'Kernel::System::ProcessManagement::TransitionAction::ZTSMStateBookResume',
    'Name' => 'TESSERA-StateBookResume'
  },
  'TransitionAction-baa9deeea687c519eb9b4141f89f94dc' => {
    'ChangeTime' => '2026-05-28 04:48:31',
    'Config' => {
      '' => ''
    },
    'CreateTime' => '2026-05-28 04:48:31',
    'Module' => 'Kernel::System::ProcessManagement::TransitionAction::ZTSMBlueBookReader',
    'Name' => 'TESSERA-BlueBookReader'
  },
  'TransitionAction-c2fc5b9b5a445ffc0d00a18a068c4b6f' => {
    'ChangeTime' => '2026-04-15 08:50:41',
    'Config' => {
      'State' => 'pending'
    },
    'CreateTime' => '2026-04-15 08:50:41',
    'Module' => 'Kernel::System::ProcessManagement::TransitionAction::TicketStateSet',
    'Name' => 'MovePending'
  },
  'TransitionAction-ccc1dda1a5588df694d7b68e87e7bafb' => {
    'ChangeTime' => '2026-04-15 08:51:06',
    'Config' => {
      'State' => 'in-progress'
    },
    'CreateTime' => '2026-04-15 08:51:06',
    'Module' => 'Kernel::System::ProcessManagement::TransitionAction::TicketStateSet',
    'Name' => 'MoveInProgress'
  },
  'TransitionAction-daa0e7534537ea4ee4427ed48041fbdc' => {
    'ChangeTime' => '2026-05-14 06:04:50',
    'Config' => {
      'State' => 'validate'
    },
    'CreateTime' => '2026-04-15 08:48:38',
    'Module' => 'Kernel::System::ProcessManagement::TransitionAction::TicketStateSet',
    'Name' => 'Submitted'
  },
  'TransitionAction-e9477b0fd144e1e8dd726f2aa73ea3fa' => {
    'ChangeTime' => '2026-04-15 08:50:00',
    'Config' => {
      'State' => 'approve'
    },
    'CreateTime' => '2026-04-15 08:50:00',
    'Module' => 'Kernel::System::ProcessManagement::TransitionAction::TicketStateSet',
    'Name' => 'MoveApprove'
  },
  'TransitionAction-eaaee915ae0a9ba4a4c826110d190e2f' => {
    'ChangeTime' => '2026-05-14 04:02:49',
    'Config' => {
      '' => ''
    },
    'CreateTime' => '2026-05-14 04:02:49',
    'Module' => 'Kernel::System::ProcessManagement::TransitionAction::TESSERAResolveGovernance',
    'Name' => 'Resolve Governance'
  },
  'TransitionAction-f8590c5dfa4a640448e2ab0f10e383f8' => {
    'ChangeTime' => '2026-04-15 08:49:07',
    'Config' => {
      'State' => 'assess'
    },
    'CreateTime' => '2026-04-15 08:49:07',
    'Module' => 'Kernel::System::ProcessManagement::TransitionAction::TicketStateSet',
    'Name' => 'MoveAssess'
  },
  'TransitionAction-faaa03a6e7b74a8324f6a950e8fd3bc5' => {
    'ChangeTime' => '2026-04-15 08:49:35',
    'Config' => {
      'State' => 'support'
    },
    'CreateTime' => '2026-04-15 08:49:35',
    'Module' => 'Kernel::System::ProcessManagement::TransitionAction::TicketStateSet',
    'Name' => 'MoveSupport'
  }
};

    return;
}
1;
