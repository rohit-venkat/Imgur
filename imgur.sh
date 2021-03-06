#!/bin/bash

set -e

# Declarations
api_key=""
required=("bash" "curl" "bc" "jsawk" "iconv")
version="1.0.0"

function main() {
  function get_album_id() {
    echo "${@}" | grep --only 'imgur.com/a/[[:alnum:]]*' | awk -F/ '{print $3}'
  }

  function get_album_name() {
    echo "$album_json" | LC_ALL=C jsawk 'return this.data.title' | iconv -f ISO-8859-1
  }

  function get_album_images() {
    echo "$album_json" | jsawk 'return this.data.images' | jsawk -n 'out(this.link)'
  }

  function get_image_id() {
    echo "${@}" | grep --only 'i.imgur.com/[[:alnum:]]*' | awk -F/ '{print $2}'
  }

  function get_image_title() {
    echo "$image_json" | jsawk 'return this.data.title'
  }

  function get_image_description() {
    echo "$image_json" | jsawk 'return this.data.description'
  }

  function continue_if_empty_var() {
    if [[ "$1" == "" ]]; then
      echo "There was an error with the album." 1>&2
      debug "continue_if_empty_var"
      continue
    fi
  }

  function continue_if_error() {
    status="$(echo "$album_json" | jsawk 'return this.status')"
    if [[ "$status" != 200 ]]; then
      echo "There was an error with the album." 1>&2
      debug "continue_if_error"
      continue
    fi
  }

  urls=("$@")
  for url in ${urls[@]}; do
    album_id="$(get_album_id "$url")"
    continue_if_empty_var "$album_id"
    debug "Album ID: $album_id"

    album_json="$(api_call "album/$album_id")"
    continue_if_empty_var "$album_json"
    continue_if_error

    album_name="$(get_album_name "$album_id")"
    album_name="${album_name//\//$(echo -e '\xE2\x81\x84')}"
    if [ -z "$album_name" ]; then
      album_name="$album_id"
    fi
    continue_if_empty_var "$album_name"
    echo "Downloading Album: \"$album_name\""

    album_images=($(get_album_images "$album_id"))
    number_of_images="${#album_images[@]}"
    continue_if_empty_var "$album_images"
    debug "Number of Images: $number_of_images"
    debug "Number of Images According to Imgur: $(echo "$album_json" | jsawk 'return this.data.images_count')"

    mkdir "$album_name" || continue

    num=0
    let "preceding_zeros = $(echo $number_of_images | wc -c)"
    for image in ${album_images[@]}; do
      continue_if_empty_var "$image"
      debug "$image"
      image_id=$(get_image_id "$image")
      image_json="$(api_call "image/$image_id")"
      image_title="$(get_image_title "$image_json")"
      image_description="$(get_image_description "$image_json")"
      debug "$image_id: $image_title"
      debug "$image_description"
      let "num += 1"
      filename="$(printf "%0${preceding_zeros}d" "$num").${image##*.}"
      debug "${album_name}/${filename}"
      curl -sL "$image" -o "${album_name}/${filename}"

      if [[ "$download_text_flag" == true ]]; then
        if [[ "${#image_title}" != 0 ]]; then
          echo "$image_title" >> "${album_name}/${filename}.txt"
          printf '%*s' "${#image_title}" | tr ' ' \# >> "${album_name}/${filename}.txt"
          echo >> "${album_name}/${filename}.txt"
        fi
        if [[ "${#image_description}" != 0 ]]; then
          echo "$image_description" >> "${album_name}/${filename}.txt"
        fi
      fi

      if [[ "$silent_flag" == false && "$num" != 0 && "$debug_flag" == false ]]; then
        percent="$(evaluate 2 "100 * $num / $number_of_images")"
        percent="${percent/.*}"
        prog="$(evaluate 2 "60 * $num / $number_of_images")"
        if [[ "$percent" =~ ^[0-9]+$ ]]; then
          progress_bar "$percent" "$prog"
        fi
        if [[ "$number_of_images" == "$num" ]]; then
          echo
        fi
        debug "Progress: $percent%"
      fi
    done
  done
}

function api_call() {
  curl -s "https://api.imgur.com/3/${@}" --header "Authorization: Client-ID ${api_key}"
}

function long_description() {
  cat << EOF
NAME
    imgur - a simple album downloader
    Version: $version

SYNOPSIS
    Download albums from imgur.com while retaining order.

OPTIONS
    -h        Show this message.
    -s        Silent mode. Overrides debug mode.
    -d        Debug mode. Overrides stdout.
    -t        Download image text, if present.

AUTHOR
    manabutameni
    https://github.com/manabutameni/Imgur

EOF
exit 0
}

function short_description() {
  stdout "usage: $0 [-sd] URL [URL]"
  exit 1
}

function update_check() {
  local new_version="$(curl -sL https://raw.github.com/manabutameni/Imgur/master/version)"
  if [[ "$new_version" != "$version" ]]; then
    echo "+-----------------------------------------------------------------+"
    echo "|              There is an update for this script.                |"
    echo "|    https://raw.github.com/manabutameni/Imgur/master/imgur.sh    |"
    echo "| changelog: https://github.com/manabutameni/Imgur/commits/master |"
    echo "+-----------------------------------------------------------------+"
  fi
}

function systems_check() {
  for command in ${required[@]}; do
    command -v "$command" > /dev/null || {
      echo "$command not installed."; exit 127
    }
  done
}

function stdout() {
  # Normal output is suppressed when debug flag is raised.
  if [[ "$debug_flag" == false ]] && [[ "$silent_flag" == false ]]; then
    echo "$@"
  fi
}

function debug() {
  # Debug output is suppressed when silent flag is raised.
  if [[ "$debug_flag" == true ]] && [[ "$silent_flag" == false ]]; then
    echo "DEBUG: $@" 1>&2
  fi
}

function evaluate() {
  scale="$1"
  shift 1
  echo "$(echo "scale=$scale; $@" | bc -q 2> /dev/null)"
}

function progress_bar() {
  printf "[%60s]       \r" " " # clear each time in case of accidental input.
  printf "[%60s] $1\045\r" " " # Print off the percent completed passed to $1
  printf "[%${2}s>\r" " " | tr ' ' '=' # Print progress bar as '=>'
  if [[ "$2" == "60.00" ]]; then
    # Display completed progress bar.
    printf "[%${2}s]\r" " " | tr ' ' '='
  fi
}

debug_flag=false
silent_flag=false
download_text_flag=false

while getopts ":hdstp" OPTION; do
  case $OPTION in
    h)
      long_description
      exit 0
      ;;
    d)
      debug_flag=true
      ;;
    s)
      silent_flag=true
      ;;
    t)
      download_text_flag=true
      ;;
    *)
      stdout "Invalid option: '-$OPTARG'"
      short_description
      ;;
  esac
done
shift $((OPTIND - 1))

systems_check 

if [[ "$debug_flag" == true ]]; then
  update_check
fi

main $@
