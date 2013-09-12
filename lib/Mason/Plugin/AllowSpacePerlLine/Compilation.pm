package Mason::Plugin::AllowSpacePerlLine::Compilation;
use Mason::PluginRole;

override _match_perl_line => method () {
    #if ( $self->{source} =~ /\G(?<=^)(%%?)([^\n]*)(?:\n|\z)/gcm ) {
    if ( $self->{source} =~ /\G(?<=^)\s*?(%%?)([^\n]*)(?:\n|\z)/gcm ) {
        my ( $percents, $line ) = ( $1, $2 );
        if ( length($line) && $line !~ /^\s/ ) {
            $self->_throw_syntax_error("$percents must be followed by whitespace or EOL");
        }
        if ( $percents eq '%%' ) {
            if ( $line =~ /\{\s*$/ && $self->{source} =~ /\G(?!%%)/gcm ) {
                $self->_throw_syntax_error("%%-lines cannot be used to surround content");
            }
        }
        $self->_handle_perl_line( ( $percents eq '%' ? 'perl' : 'class' ), $line );
        $self->{line_number}++;

        return 1;
    }
    return 0;
};

override _match_plain_text => method () {

    # Most of these terminator patterns actually belong to the next
    # lexeme in the source, so we use a lookahead if we don't want to
    # consume them.  We use a lookbehind when we want to consume
    # something in the matched text, like the newline before a '%'.

    if (
        $self->{source} =~ m{
                                \G
                                (.*?)         # anything, followed by:
                                (
                                #(?<=\n)(?=%) # an eval line - consume the \n
                                 (?<=\n)(?=\s*%) # an eval line - consume the \n
                                 |
                                 (?=<%\s)     # a substitution tag
                                 |
                                 (?=[%&]>)    # an end substitution or component call
                                 |
                                 (?=</?[%&])  # a block or call start or end
                                              # - don't consume
                                 |
                                 \\\n         # an escaped newline  - throw away
                                 |
                                 \z           # end of string
                                )
                               }xcgs
      )
    {
        my ( $orig_text, $swallowed ) = ( $1, $2 );
        my $text = $orig_text;

        # Chomp newline before block start
        #
        if ( substr( $self->{source}, pos( $self->{source} ), 3 ) =~ /<%[a-z]/ ) {
            chomp($text);
        }
        $self->_handle_plain_text($text) if length $text;

        # Not checking definedness seems to cause extra lines to be
        # counted with Perl 5.00503.  I'm not sure why - dave
        $self->{line_number} += tr/\n// foreach grep defined, ( $orig_text, $swallowed );

        return 1;
    }

    return 0;
};

1;
