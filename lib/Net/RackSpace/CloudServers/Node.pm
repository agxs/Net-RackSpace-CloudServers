package Net::RackSpace::CloudServers::Node;
use warnings;
use strict;
our $DEBUG = 0;
use Any::Moose;
use Any::Moose ( '::Util::TypeConstraints' );
use HTTP::Request;
use JSON;
use YAML;
use Carp;

has 'cloudservers' => ( is => 'rw', isa => 'Net::RackSpace::CloudServers', required => 1 );
has 'id'           => ( is => 'ro', isa => 'Int', required => 1, default => 0 );
has 'loadbalancerid' => ( is => 'rw', isa => 'Int', required => 1 );
has 'address'      => ( is => 'rw', isa => 'Str', required => 1);
has 'port'         => ( is => 'rw', isa => 'Int', required => 1);

subtype ValidCondition => as 'Str' => where { $_ eq 'ENABLED' or
                                              $_ eq 'DISABLED' or
                                              $_ eq 'DRAINING' };

has 'condition'    => ( is => 'rw', isa => 'ValidCondition', required => 1);
has 'status'       => ( is => 'rw', isa => 'Str', required => 1, default => 0 );
has 'weight'       => ( is => 'rw', isa => 'Maybe[Int]', required => 0, default => undef );

no Any::Moose;
__PACKAGE__->meta->make_immutable();

sub create {
  my $self = shift;
  my $request = HTTP::Request->new (
    'POST',
    $self->cloudservers->lb_management_url . '/loadbalancers/'
                                           . $self->loadbalancerid
                                           . '/nodes',
    [
      'X-Auth-Token' => $self->cloudservers->token,
      'Content-Type' => 'application/json',
    ],
    to_json(
      {
        nodes => [{
          address   => $self->address,
          port      => int $self->port,
          condition => $self->condition,
          defined $self->weight ? ( weight => $self->weight ) : (),
        }]
      }
    )
  );
  my $response = $self->cloudservers->_request($request);
  confess 'Unknown error' if !($response->code == 202 or
                               $response->code == 200 );
  my $hash_response = from_json( $response->content );
  warn Dump($hash_response) if $DEBUG;
  my $hnode = $hash_response->{nodes}->[0];
  return Net::RackSpace::CloudServers::Node->new(
    cloudservers   => $self->{cloudservers},
    id             => $hnode->{id},
    loadbalancerid => $self->{loadbalancerid},
    address        => $hnode->{address},
    port           => $hnode->{port},
    status         => $hnode->{status},
    condition      => $hnode->{condition},
    weight         => $hnode->{weight},
  );
}

sub delete {
  my $self = shift;
  my $request = HTTP::Request->new (
    'DELETE',
    $self->cloudservers->lb_management_url . '/loadbalancers/'
                                           . $self->loadbalancerid
                                           . '/nodes/'
                                           . $self->id,
    [
      'X-Auth-Token' => $self->cloudservers->token,
      'Content-Type' => 'application/json',
    ],
  );
  my $response = $self->cloudservers->_request($request);
  confess 'Unknown error' if !($response->code == 202 or
                               $response->code == 200 );
}

