import React, { useState, useEffect, useRef, Fragment } from "react";
import {
  Form,
  Button,
  Header,
  Table,
  Segment,
  Divider,
  Grid,
  Icon,
  ButtonContent,
} from "semantic-ui-react";
import _ from "lodash";
import moment from "moment";

import "semantic-ui-css/semantic.min.css";
import "../Styles/default";

import { DateInput } from "semantic-ui-calendar-react";
import axios from "axios";

var page = 1;
var block = false;
const default_params = {
  term: "",
  action_type: "All",
  user: "All",
  date_from: "",
  date_to: "",
  page: 1,
};

export default function Timeline(props) {
  const listInnerRef = useRef();
  const [records, setRecords] = useState([]);
  const [users, setUsers] = useState({});
  const [params, setParams] = useState(default_params);
  const [submitted, setSubmitted] = useState(false);
  const [loading, setLoading] = useState(false);

  // console.log("Timeline", props);

  useEffect(() => {
    let obj = {};
    props.users.forEach((user) => {
      obj[user.id] = user;
    });

    setUsers(obj);
    setRecords(props.records);
  }, []);

  const handleSubmit = () => {
    page = 1;
    scrolToTop();
    submit();
  };

  const submit = () => {
    // console.log("Submit", params, page);
    setSubmitted(true);
    setLoading(true);
    axios
      .get("/timeline.json", {
        params: {
          term: params.term,
          action_type: params.action_type,
          user: params.user,
          date_from: params.date_from,
          date_to: params.date_to,
          page: page,
        },
      })
      .then((response) => {
        // console.error("response", response.data);

        if (page > 1) {
          let cur_records = [...records];
          setRecords(cur_records.concat(response.data));
        } else {
          setRecords(response.data);
        }
        loading = { submitted };
        disabled = { submitted };
      });
  };

  const resetForm = () => {
    setParams(default_params);
    page = 1;
    scrolToTop();
    submit();
  };

  const scrolToTop = () => {
    document.getElementById("content").scrollTop = 0;
  };

  const handleChange = (e, { name, value }) => {
    // console.log("handleChange", name, value);
    let obj = { ...params };
    obj[name] = value;
    obj.page = 1;
    setParams(obj);
  };

  const onScroll = () => {
    if (listInnerRef.current) {
      const { scrollTop, scrollHeight, clientHeight } = listInnerRef.current;
      // console.log({
      //   scrollTop,
      //   scrollHeight,
      //   clientHeight,
      //   calc: scrollTop + clientHeight,
      //   subtract: scrollTop + clientHeight - scrollHeight,
      // });
      let total = scrollTop + clientHeight - scrollHeight;
      if (total <= 1 && total >= -1 && !block) {
        // console.log("reached bottom", page);
        block = true;
        page += 1;
        submit();
      } else {
        block = false;
      }
    }
  };

  return (
    <Fragment>
      <TimelineSidebar
        params={params}
        users={props.users}
        actions={props.actions}
        handleSubmit={handleSubmit}
        resetForm={resetForm}
        handleChange={handleChange}
      />
      <div id="content" onScroll={onScroll} ref={listInnerRef}>
        {
          <div
            id="timeline-table"
            className="table-overflow no-padding no-margin"
          >
            <Table
            stackable
              attached
              celled
              striped
              style={{
                width: "100%",
                margin: "0",
                maxWidth: "100%",
                border: "none",
                borderBottom: "1px solid #d4d4d5",
              }}
            >
              <Table.Header>
                <Table.Row>
                  <Table.HeaderCell>Action</Table.HeaderCell>
                  <Table.HeaderCell>Message</Table.HeaderCell>
                  <Table.HeaderCell>Logged At</Table.HeaderCell>
                  <Table.HeaderCell>User</Table.HeaderCell>
                  <Table.HeaderCell></Table.HeaderCell>
                </Table.Row>
              </Table.Header>
              <Table.Body>
                {records.map((record, index) => {
                  return (
                    <Table.Row key={index}>
                      <Table.Cell>
                        <Header as="h4">
                          <Header.Content>{record.action_type}</Header.Content>
                        </Header>
                      </Table.Cell>
                      <Table.Cell>{record.message}</Table.Cell>
                      <Table.Cell>
                        {moment(record.created_at).format("M/D/YY h:mm A")}
                      </Table.Cell>
                      <Table.Cell>
                        {users[record.creator_id].full_name}
                      </Table.Cell>
                      <Table.Cell collapsing>
                        <Button icon as="a" href={`/timeline/${record.id}`}>
                          <Icon name="external alternate" />
                        </Button>
                      </Table.Cell>
                    </Table.Row>
                  );
                })}
              </Table.Body>
            </Table>
          </div>
        }
      </div>
    </Fragment>
  );
}

function TimelineSidebar({
  params,
  users,
  actions,
  handleSubmit,
  resetForm,
  handleChange,
}) {
  return (
    <div id="sidebar" style={{ overflowY: "auto", overflowX: "hidden" }}>
      <Header as="h4">Timeline</Header>
      <Divider />
      <Form onSubmit={handleSubmit}>
        <Form.Field>
          <Form.Input
            autoComplete="off"
            label="Search Term"
            name="term"
            value={params.term}
            onChange={handleChange}
          />
        </Form.Field>
        <Form.Field>
          <Form.Select
            search
            fluid
            label="Action"
            name="action_type"
            value={params.action_type}
            autoComplete="off"
            onChange={handleChange}
            options={["All"].concat(actions).map((action, index) => {
              return {
                key: index,
                text: action,
                value: action,
              };
            })}
          />
        </Form.Field>
        <Form.Field>
          <Form.Select
            search
            fluid
            label="User"
            name="user"
            value={params.user}
            autoComplete="off"
            onChange={handleChange}
            options={[{ id: "All", full_name: "All" }]
              .concat(users)
              .map((user) => {
                return {
                  key: user.id,
                  text: user.full_name,
                  value: user.id,
                };
              })}
          />
        </Form.Field>
        <Form.Field>
          <div className="calendar-input">
            <DateInput
              clearable
              closable
              name="date_from"
              label="Date From (UTC):"
              placeholder="Date"
              iconPosition="left"
              dateFormat="MM/DD/YYYY"
              autoComplete="off"
              value={params.date_from}
              onChange={handleChange}
            />
          </div>
        </Form.Field>
        <Form.Field>
          <div className="calendar-input">
            <DateInput
              clearable
              closable
              name="date_to"
              label="Date To (UTC):"
              placeholder="Date"
              iconPosition="left"
              dateFormat="MM/DD/YYYY"
              autoComplete="off"
              value={params.date_to}
              onChange={handleChange}
            />
          </div>
        </Form.Field>
        <Divider />
        <Grid>
          <Grid.Row>
            <Grid.Column width={8} style={{ paddingRight: "0.25em" }}>
              <Button fluid type="button" animated onClick={resetForm}>
                <ButtonContent visible>Reset</ButtonContent>
                <ButtonContent hidden>
                  <Icon name="undo" />
                </ButtonContent>
              </Button>
            </Grid.Column>
            <Grid.Column width={8} style={{ paddingLeft: "0.25em" }}>
              <Button fluid animated primary type="submit">
                <ButtonContent visible>Submit</ButtonContent>
                <ButtonContent hidden>
                  <Icon name="arrow right" />
                </ButtonContent>
              </Button>
            </Grid.Column>
          </Grid.Row>
        </Grid>
      </Form>
    </div>
  );
}
