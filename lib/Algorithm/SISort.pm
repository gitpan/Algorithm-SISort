package Algorithm::SISort;

require 5.005_62;
use strict;
use warnings;
use Inline C => 'DATA';

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	Sort
	Sort_inplace
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );

our $VERSION = '0.10';

sub Sort(&@) {
	my $callback=shift;
	my @array_copy=@_;
	_sort($callback, \@array_copy);
	return @array_copy;
}

sub Sort_inplace(&\@) {
	my $callback=shift;
	return _sort($callback, $_[0]);
}

1;

__DATA__


=head1 NAME

Algorithm::SISort - Implementation of Select And Insert sorting algorithm in C

=head1 SYNOPSIS

  use Algorithm::SISort qw(Sort Sort_inplace);
  
  @sorted_list = Sort {$_[0] <=> $_[1]} @unsorted_list;
  # ... or ...
  Sort_inplace {$_[0] <=> $_[1]} @unsorted_list;

=head1 DESCRIPTION

This module implements a sorting algorithm I saw in BIT 28 (1988) by István
Beck and Stein Krogdahl. This implmentation is mainly intended to try out the
Inline module by Brian Ingerson. The algorithim is a combination of I<Straight
Insertion Sort> and I<Selection Sort>. While I<Insertion Sort> and I<Selection
Sort> both are of complexity O(n**2), I<Select and Insert Sort> should have
complexitiy O(n**1.5).

This module defines the functions C<Sort> and C<Sort_inplace>, which have
signatures similar to the internal C<sort> function. The difference is that a
codref defining a comparison is always required and that the two values to
compare are always passed in C<@_> and not as C<$a> and C<$b>. (Although I
might change that later.)

C<Sort> returns a sorted copy if the array, but C<Sort_inplace> sorts the array
in place (as the name suggests) and returns the number of comparisons done. 
(Note that the sorting is always done in place, C<Sort> just copies the array
before calling the internal sort routine.)

=head1 BUGS

This is the first serious (i.e. not "Hello World") C-extension I've done, so
I suspect I've screwed around with the refcounts of the list entries. Until I've
confirmed that there are no memory leaks, I caution people not to use this
peace of code in any production system. 

Any bug-reports, comments and patches are very welcome at my email address
below.

=head1 SEE ALSO

L<Inline>, L<Inline::C>, and I<A Select And Insert Sorting Algorithm> by István
Beck and Stein Krogdahl in I<BIT 28 (1988), 726-735>.

=head1 AUTHOR

Hrafnkell F. Hlodversson, keli@shebang.dk

=head1 COPYRIGHT

Copyright 2001, Hrafnkell F Hlodversson

All Rights Reserved.  This module is free software. It may
be used, redistributed and/or modified under the terms of
the Perl Artistic License.

See http://www.perl.com/perl/misc/Artistic.html

=cut

__C__

static int compare( SV* callback,  SV* a, SV* b) {
	int retnum,numres;
	dSP;
	SvREFCNT_inc(a);
	SvREFCNT_inc(b);
	
	ENTER;
	SAVETMPS;
	
	PUSHMARK(sp);
	XPUSHs(a);
	XPUSHs(b);
	PUTBACK;
	
	numres=call_sv(SvRV(callback), G_SCALAR);
	
	SPAGAIN;
	
	if(numres==1) {
		retnum = POPi;
	} else {
		retnum = 0;
	}
	
	PUTBACK;
	FREETMPS;
	LEAVE;
	return retnum;
}

int _sort (SV* callback, SV* arrayref) {
	int n; /* last element of array */
	int i, j,  minj, step, ncompares;
	SV *min, **minp, **A_i, **A_j, **ptr, **zero;
	AV* A;
	
	ncompares=0;
	A=(AV*)SvRV(arrayref);
	/* Add a temporary spare room at the front: */
	av_unshift(A,1);av_store(A,0,sv_newmortal()); 
	
	n=av_len(A);
	zero=av_fetch(A,0,0);
	for(i=1;i<=n;i++) {
		A_i=av_fetch(A,i,0);
		min  = *A_i;
		minp = A_i;
		minj = i;
		step = 1;
		j	 = i+step;
		
		/* Select a "minimalish" element: */
		while ( j <= n ) {
			A_j=av_fetch(A,j,0);
			ncompares++;
			if( compare(callback, *A_j, min ) < 0 )  {
				min=*A_j;
				minp=A_j;
				minj=j;
			}
			step++;
			j+=step;
		}
		
	
		/* Start insertion: */
		*minp=*A_i;
		*zero=min; 
		
		j = i-1;
		A_j=av_fetch(A,j,0);
		while ( compare(callback, *A_j, min ) > 0 ) {
			ncompares++;
			ptr=av_fetch(A,j+1,0);
			*ptr=*A_j;
			
			j--;
			A_j=av_fetch(A,j,0);
		}
		ncompares++;
		ptr=av_fetch(A,j+1,0);
		*ptr=min;
	}
	/* Remove the temporary spare room at the front: */
	av_shift(A);
	return ncompares;

}
