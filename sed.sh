#!/bin/sh

tmpfile=${TMPDIR:-/tmp}/sed.${USER:=$(id)}.$$
sed=/usr/bin/sed

sed_i() {
	file=$1 backup_suffix=$2
	shift 2

	# We can't edit stdin in-place.
	[ "$file" = "-" ] &&
		file=./-

	# Everything following is critical. Enable errexit so we don't
	# have to manually handle the exit status of every program.
	set -e

	# In order to preserve the file permissions, we copy the target
	# file.
	cp -f -- "$file" "$tmpfile"

	# Do the actual in-place edit.
	"$sed" "$@" "$file" >"$tmpfile"

	# Make a backup if desired.
	if [ "$backup_suffix" ]; then
		mv -f -- "$file" "$file$backup_suffix"
	fi

	# Overwrite the original file.
	mv -f -- "$tmpfile" "$file"

	set +f
}

cleanup() {
	rv=$?
	trap - EXIT

	[ -f "$tmpfile" ] &&
		rm -f -- "$tmpfile"

	exit "$rv"
}
trap cleanup EXIT HUP INT TERM

unset -v argsunset isparam isoperand hasexpr iflag iparam

for arg do
	# In order to be able to append the translated options, unset the
	# positional parameters on the first run.
	! [ "$argsunset" ] && {
		argsunset=1
		set --
	}

	# When option parsing is complete (the current argument is an
	# operand) and we don't do in-place editing, we can simply append
	# all remaining arguments and eventually run a single $sed at the
	# end of the script. Otherwise we run the sed_i function for
	# every file argument. $isoperand is set when either "--" or the
	# first non-option argument is encountered.
	[ "$isoperand" ] && {
		if ! [ "$iflag" ]; then
			set -- "$@" "$arg"
		else
			sed_i "$arg" "$iparam" "$@"
		fi

		continue
	}

	# The previous option requires a parameter.
	[ "$isparam" ] && {
		set -- "$@" "$arg"
		unset isparam

		continue
	}

	# Parse options.
	case $arg in
		# "--" marks the end of the options.
		--)
			isoperand=1
			set -- "$@" "$arg"
		;;

		# The first non-option argument marks the end of the
		# options. However, if no -e or -f option was used, this
		# argument is used as the sed expression.
		[!-]*|-)
			isoperand=1

			if [ "$hasexpr" ] && [ "$iflag" ]; then
				sed_i "$arg" "$iparam" "$@"
			else
				set -- "$@" "$arg"
			fi
		;;

		# Long options.
		################################################

		--in-place|--in-place=*)
			iflag=1

			case $arg in
				*=*) iparam=${arg#*=} ;;
			esac
		;;

		--expression|--expression=*|--file|--file=*)
			hasexpr=1

			case $arg in
				--e*) set -- "$@" -e ;;
				--f*) set -- "$@" -f ;;
			esac

			case $arg in
				*=*) set -- "$@" "${arg#*=}" ;;
				*) isparam=1 ;;
			esac
		;;

		--quiet|--silent)
			set -- "$@" -n
		;;

		--regexp-extended)
			set -- "$@" -r
		;;

		# All other long-options will be passed as is, letting
		# $sed complain about unknown options itself.
		--?*)
			set -- "$@" "$arg"
		;;

		# Short options.
		################################################

		# Options with parameters. The first occurence of [efi]
		# marks everything after it as the parameter. If the
		# parameter is missing, we get it from the next argument.
		# Except for -i, where the parameter is optional and has
		# to be supplied in the same argument.
		-*[efi]*)
			arg=${arg#-}

			# Extract the last option and its parameter.
			param=${arg#*[efi]}
			lastopt=${arg%$param}
			lastopt=${lastopt##*[!efi]}

			# Extract the other options, without the last one
			# and its parameter.
			opts=${arg%%$lastopt*}

			# Other options are simply appended to the
			# positional parameters.
			[ "$opts" ] &&
				set -- "$@" "-$opts"

			case $lastopt in
				[ef])
					hasexpr=1

					if [ "$param" ]; then
						set -- "$@" "-$lastopt" "$param"
					else
						set -- "$@" "-$lastopt"
						isparam=1
					fi
				;;

				i)
					iflag=1
					iparam=$param
				;;
			esac
		;;

		# All other options will be passed as is, letting $sed
		# complain about unknown options itself.
		-*)
			set -- "$@" "$arg"
		;;
	esac
done

# If we have a -i option, we are done at this point.
[ "$iflag" ] && exit $?

# Without -i, we can simply run the original sed once, with all the
# translated options and file arguments.
"$sed" "$@"
