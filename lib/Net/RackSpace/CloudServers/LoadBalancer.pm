package Net::RackSpace::CloudServers::LoadBalancer;
use warnings;
use strict;
our $DEBUG = 0;
use Any::Moose;
use HTTP::Request;
use Net::RackSpace::CloudServers::Node;
use JSON;
use YAML;
use Carp;

has 'cloudservers' => ( is => 'rw', isa => 'Net::RackSpace::CloudServers', required => 1 );
has 'id'           => ( is => 'ro', isa => 'Int',        required => 1, default => 0 );
has 'name'         => ( is => 'ro', isa => 'Str',        required => 1 );
has 'status'       => ( is => 'ro', isa => 'Maybe[Str]', required => 1, default => undef );
has 'protocol'     => ( is => 'ro', isa => 'Str',        required => 1 );
has 'port'         => ( is => 'ro', isa => 'Str',        required => 1 );
has 'algorithm'    => ( is => 'ro', isa => 'Str',        required => 1 );
has 'created'      => ( is => 'ro', isa => 'Str',        required => 1, default => 0 );
has 'updated'      => ( is => 'ro', isa => 'Str',        required => 1, default => 0 );
has 'virtualIps'   => ( is => 'ro', isa => 'Maybe[ArrayRef[HashRef]]',        required => 1 );

no Any::Moose;
__PACKAGE__->meta->make_immutable();

sub get_nodes {
  my $self = shift;
  my $id = shift;
  my $uri = defined $id ? '/loadbalancers/' . $self->id . '/nodes/' . $id
                        : '/loadbalancers/' . $self->id . '/nodes';
  my $request = HTTP::Request->new(
    'GET',
    $self->cloudservers->lb_management_url . $uri,
    [
      'X-Auth-Token' => $self->cloudservers->token,
      'Content-Type' => 'application/json',
    ],
  );
  my $response = $self->cloudservers->_request($request);
  confess 'Unknown error' if !($response->code == 200 or
                               $response->code == 202);

  my $hash_response = from_json( $response->content );
  warn Dump($hash_response) if $DEBUG;

  return map {
    Net::RackSpace::CloudServers::Node->new(
      cloudservers   => $self->cloudservers,
      id             => $_->{id},
      loadbalancerid => $self->id,
      address        => $_->{address},
      port           => $_->{port},
      condition      => $_->{condition},
      status         => $_->{status},
      weight         => $_->{weight},
    )
  } @{ $hash_response->{nodes} } if ( !defined $id );

  return Net::RackSpace::CloudServers::Node->new(
    cloudservers   => $self->cloudservers,
    id             => $hash_response->{id},
    loadbalancerid => $self->id,
    address        => $hash_response->{address},
    port           => $hash_response->{port},
    condition      => $hash_response->{condition},
    status         => $hash_response->{status},
    weight         => $hash_response->{weight},
  );
}

