import React, { useState, useEffect, useRef, Fragment } from "react";
import {
  Input,
  Button,
  Popup,
  Menu,
  Transition,
  Divider,
  List,
  Icon,
  Dropdown,
} from "semantic-ui-react";
import _ from "lodash";
import moment from "moment";
import axios from "axios";

import "semantic-ui-css/semantic.min.css";
import "./Styles/JobTracker.css";
import "./Styles/default";

var intervalHandler;
export default function JobTracker() {
  const [records, setRecords] = useState([]);
  const [active, setActive] = useState(false);
  const [nag, setNag] = useState(false);
  const [popupOpen, setPopupOpen] = useState(false);
  const [intervalAmount, setIntervalAmount] = useState(60000); // Every 60 seconds
  const [width, setWidth] = useState(window.innerWidth);
  useEffect(() => {
    const handleResize = () => setWidth(window.innerWidth);
    window.addEventListener("resize", handleResize);
    return () => window.removeEventListener("resize", handleResize);
  }, []);

  useEffect(() => {
    fetch();
    // Add a little delay in case the user submits the request and the job takes a couple seconds
    setTimeout(fetch, 5000);

    document.addEventListener("visibilitychange", (ev) => {
      if (document.visibilityState == "visible") fetch();
    });
    window.addEventListener("focus", () => {
      fetch();
    });
  }, []);

  useEffect(() => {
    if (intervalHandler) clearInterval(intervalHandler);
    intervalHandler = setInterval(() => {
      fetch();
    }, intervalAmount);
  }, [intervalAmount]);

  const fetch = () => {
    // send a request to the server
    axios.get("/job_requests").then((response) => {
      // console.log("fetch", { response });

      // Update the records
      setRecords(response.data.records);

      if (!popupOpen) {
        // Update the animation if there is a new active record
        // Else check if there is a new record that has a newer create date than the value in localstorage
        // => if nothing in localstorage then throw nag
        if (active && !response.data.active) {
          setNag(moment().unix());
        } else if (response.data.records.length) {
          const lastOpenedUnix = localStorage.getItem("jobTracker");
          if (lastOpenedUnix) {
            // console.log({
            //   lastOpenedUnix,
            //   firstRecord: moment(response.data.records[0].finished_at).unix(),
            //   eval:
            //     lastOpenedUnix <
            //     moment(response.data.records[0].finished_at).unix(),
            // });
            setNag(
              lastOpenedUnix >
                moment(response.data.records[0].updated_at).unix()
                ? moment().unix()
                : false
            );
          } else {
            setNag(moment().unix());
          }
        }
      }

      // check if the
      if (active != response.data.active) {
        // console.log("asdf", active, response.data.active);
        setActive(response.data.active);
        setIntervalAmount(response.data.active ? 30000 : 60000);
      }
    });
  };

  const setLastOpened = () => {
    setNag(false);
    setPopupOpen(true);
    localStorage.setItem("jobTracker", moment().unix());
  };

  const renderIcon = (record) => {
    if (record.success && record.finished_at) {
      return (
        <Icon
          size="large"
          name="checkmark"
          color="green"
          style={{ verticalAlign: "middle !important" }}
        />
      );
    } else if (!record.success && record.finished_at) {
      return (
        <Icon
          size="large"
          name="remove"
          color="red"
          style={{ verticalAlign: "middle !important" }}
        />
      );
    } else {
      return (
        <Icon
          loading
          size="large"
          name="circle notch"
          style={{ verticalAlign: "middle !important" }}
        />
      );
    }
  };

  const renderRecords = () => {
    if (records.length == 0) return "No Jobs Found";

    return (
      <List divided>
        <List.Item>
          <List.Description style={{ textAlign: "center", fontSize: "9pt" }}>
            <i>Last Checked at {moment().format("LLL")}</i>
          </List.Description>
        </List.Item>
        {records.map((record, index) => {
          return (
            <List.Item key={`list_${index}`} style={{ padding: "0.75em 0" }}>
              {renderIcon(record)}
              <List.Content style={{ paddingLeft: "1em" }}>
                <List.Header>{record.process_type}</List.Header>
                <Divider style={{ margin: "0.25em 0", padding: 0 }} />
                <List.Description>
                  {record.error_message ? record.error_message : record.message}
                </List.Description>

                <List.Description
                  style={{ marginTop: "0.5em", fontSize: "9pt" }}
                >
                  <Icon name="file" />
                  <b>
                    {record.filename
                      ? record.filename
                      : "Filename Not Recorded"}
                  </b>
                </List.Description>
                <List.Description
                  style={{ marginTop: "0.5em", fontSize: "9pt" }}
                >
                  {record.active ? (
                    <i>
                      Started at {moment(record.started_at).format("l h:mm A")}{" "}
                      by {record.creator}
                    </i>
                  ) : (
                    <i>
                      {`Completed at ${moment(record.finished_at).format(
                        "l h:mm A"
                      )} by ${record.creator} `}
                    </i>
                  )}
                </List.Description>
              </List.Content>
            </List.Item>
          );
        })}
      </List>
    );
  };

  const renderButtonIcon = () => {
    // console.error("renderButtonIcon", nag);
    if (active) {
      return <Icon loading name="circle notch" />;
    } else if (nag) {
      return (
        <Transition
          visible={true}
          key={nag}
          transitionOnMount={true}
          animation="jiggle"
          duration={500}
        >
          <Icon color="yellow" name="bullhorn" />
        </Transition>
      );
    } else {
      return null;
    }
  };

  // console.error("JobTracker", { active, records, intervalAmount, popupOpen });

  return (
    <Popup
      pinned
      id="job_tracker_popup"
      content={renderRecords()}
      on="click"
      wide="very"
      position="bottom right"
      onOpen={setLastOpened}
      onClose={() => setPopupOpen(false)}
      style={{ overflowY: "auto", maxHeight: "500px" }}
      trigger={
        <Menu.Item active={popupOpen} onClick={() => fetch()}>
          {renderButtonIcon()}
          {width > 768 ? "Job Tracker" : !active && <Icon name="alarm" />}
        </Menu.Item>
      }
    />
  );
}
